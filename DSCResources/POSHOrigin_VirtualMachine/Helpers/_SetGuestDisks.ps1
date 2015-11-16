function _SetGuestDisks{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DiskSpec,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    begin {
        Write-Debug -Message 'Starting _SetGuestDisks()'
    }

    process {
        try { 
            $mapping = _GetGuestDiskToVMDiskMapping -vm $vm -DiskSpec $DiskSpec

            $t = Get-VM -Id $vm.Id -Verbose:$false -Debug:$false
            $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1

            if ($null -ne $ip -and $ip -ne [string]::Empty) {

                # Let's do a sanity check first.
                # Make sure we passed in valid values for the block size
                # If we didn't, let's stop right here
                $blockSizes = @(
                    4096, 8192, 16386, 32768, 65536
                )
                $mapping | foreach {
                    # Set default block size
                    if ($_.BlockSize -eq $null) {
                        $_.BlockSize = 4096
                    }
                    if ($blockSizes -notcontains $_.BlockSize) {
                        Write-Error -Message 'Invalid block size passed in. Aborting configuration the disks'
                        break
                    }
                }
                
                $cim = New-CimSession -ComputerName $ip -Credential $Credential -Verbose:$false
                $session = New-PSSession -ComputerName $ip -Credential $credential -Verbose:$false
                $wmiDisks = Get-CimInstance -CimSession $cim -ClassName Win32_DiskDrive -Verbose:$false            
                #$disks = Get-Disk -CimSession $cim -Verbose:$false
                $disks = Invoke-Command -Session $session -ScriptBlock { Get-Disk } -Verbose:$false

                # If the VM has a cdrom, mount it as 'Z:'

                if (((Get-CimInstance -CimSession $cim -ClassName win32_cdromdrive -Verbose:$false) | Where-Object {$_.Caption -like "*vmware*"} | Select-Object -First 1).Drive -ne "Z:") {
                    Write-Verbose -Message 'Changing CDROM to Z:'
                    $cd = (Get-CimInstance -CimSession $cim -ClassName Win32_cdromdrive -Verbose:$false) | Where-Object {$_.Caption -like "*vmware*"}
                    $oldLetter = $cd.Drive
                    $cdVolume = Get-CimInstance -CimSession $cim -ClassName Win32_Volume -Filter "DriveLetter='$oldLetter'" -Verbose:$false
                    Set-CimInstance -CimSession $cim -InputObject $cdVolume -Property @{DriveLetter='Z:'} -Verbose:$false
                }                

                # Format each disk according to instructions
                foreach ($config in $mapping) {
                    $match = $wmiDisks | Where-Object {($_.SCSIBus -eq $config.SCSIController) -and ($_.SCSITargetId -eq $config.SCSITarget)} | Select-Object -First 1
                    #write-host ($match | fl * | out-string)

                    if ($null -ne $match) {
                        $disk = $disks | Where-Object {$_.SerialNumber -eq $match.SerialNumber} | select -first 1
                        if ($null -ne $disk) {
                            write-debug ($disk | fl * | out-string)
                            Write-Debug -Message "Looking at disk $($disk.Number)"
                            #Write-Verbose -Message "Configuring disk $($disk.Number)"

                            # Online the disk            
                            if ($disk.IsOffline -eq $true) {
                                Write-Debug -Message "Bringing disk [ $($disk.Number) ] online"
                                #$disk | Set-Disk -CimSession $cim -IsOffline $false -Verbose:$false
                                Invoke-Command -Session $session -ScriptBlock { $args[0] | Set-Disk -IsOffline $false } -ArgumentList $disk -Verbose:$false
                            } else {
                                Write-Debug -Message "Disk $($disk.Number) is already online"
                            }

                            if ($disk.PartitionStyle -eq 0) {
                                Write-Verbose -Message "Initializing disk $($disk.Number)"
                                #$disk | Initialize-Disk -CimSession $cim -PartitionStyle GPT -Verbose:$false -PassThru |                                
                                #New-Partition -CimSession $cim -DriveLetter $config.VolumeName -UseMaximumSize -Verbose:$false |
                                #Format-Volume -CimSession $cim -FileSystem NTFS -NewFileSystemLabel $config.VolumeLabel -AllocationUnitSize $config.BlockSize –Force -Verbose:$false -Confirm:$false | Out-Null
                                $cmd = {
                                    $args[0] | Initialize-Disk -PartitionStyle GPT -Verbose:$false -PassThru |
                                        New-Partition -DriveLetter $args[1] -UseMaximumSize -Verbose:$false |
                                        Format-Volume -FileSystem NTFS -NewFileSystemLabel $args[2] -AllocationUnitSize $args[3] -Force -Verbose:$false -Confirm:$false | Out-Null
                                }
                                Invoke-Command -Session $session -ScriptBlock $cmd -ArgumentList @($disk, $config.VolumeName, $config.VolumeLabel, $config.BlockSize ) -Verbose:$false
                            
                            } else {
                                #$result = @($disk | Get-Partition -CimSession $cim -Verbose:$false | Where-Object {$_.Type -ne 'Reserved' -and $_.IsSystem -eq $false})
                                $result = Invoke-Command -Session $session -ScriptBlock { @($args[0] | Get-Partition | Where-Object {$_.Type -ne 'Reserved' -and $_.IsSystem -eq $false}) } -ArgumentList $disk
                                if ( $result.Count -eq 0) {
                                    #$disk | New-Partition -CimSession $cim -DriveLetter $config.VolumeName -UseMaximumSize -Verbose:$false |
                                    #Format-Volume -CimSession $cim -FileSystem NTFS -NewFileSystemLabel $config.VolumeLabel -AllocationUnitSize $config.BlockSize –Force -Verbose:$false -Confirm:$false | Out-Null
                                    $cmd = {
                                        $args[0] | New-Partition -DriveLetter $args[1] -UseMaximumSize |
                                            Format-Volume -FileSystem NTFS -NewFileSystemLabel $args[2] -AllocationUnitSize $args[3] -Force -Verbose:$false -Confirm:$false | Out-Null
                                    }
                                    Invoke-Command -Session $session -ScriptBlock $cmd -ArgumentList @($disk, $config.VolumeName, $config.VolumeLabel, $config.BlockSize) -Verbose:$false 
                                }                                  
                            }
                        } else {
                            Write-Verbose -Message 'Could not find matching disk'
                        }
                    } else {
                        Write-Verbose -Message "Could not find disk $($config.SCSIController):$($config.SCSITarget)"
                    }
                }

                # Compare the formated guest volumes with the mapping configuration
                # if the matching volume from the mapping has a size greater
                # than what exists, then extend the volume to match the configuration
                # BIG ASSUMPTION
                # There is only one volume per disk                
                $wmiDisks = Get-CimInstance -CimSession $cim -ClassName Win32_DiskDrive -Verbose:$false
                #$formatedDisks = Get-Disk -CimSession $cim -Verbose:$false | Where-Object {$_.PartitionStyle -ne 'Raw'}
                $formatedDisks = Invoke-Command -Session $session -ScriptBlock { Get-Disk | Where-Object {$_.PartitionStyle -ne 'Raw'} }
                foreach ($config in $mapping) {
                    $match = $wmiDisks | Where-Object {($_.SCSIBus -eq $config.SCSIController) -and ($_.SCSITargetId -eq $config.SCSITarget)} | select -First 1
                    if ($null -ne $match) {
                        $disk = $formatedDisks | Where-Object {$_.SerialNumber -eq $match.SerialNumber} | Select-Object -first 1
                        if ($null -ne $disk) {                        
                            Write-Debug -Message "Looking at disk $($disk.Number)"
                            #$partition = $disk | Get-Partition -CimSession $cim -Verbose:$false | Where-Object {$_.Type -ne 'Reserved' -and $_.IsSystem -eq $false} | Select-Object -First 1
                            $partition = Invoke-Command -Session $session -ScriptBlock { $args[0] | Get-Partition | Where-Object {$_.Type -ne 'Reserved' -and $_.IsSystem -eq $false} | Select-Object -First 1 } -ArgumentList $disk -Verbose:$false 
                            #$sizes = $partition | Get-PartitionSupportedSize -CimSession $cim -Verbose:$false | Select-Object -Last 1
                            $sizes = Invoke-Command -Session $session -ScriptBlock { $args[0] | Get-PartitionSupportedSize | Select-Object -Last 1 } -ArgumentList $partition -Verbose:$false
                            # The max partition size is greater than the current partition size

                            Write-Debug -Message "Partition size: $($partition.Size)"
                            Write-Debug -Message "Paritition max size: $($sizes.SizeMax)"
                            if ( [math]::round($partition.Size / 1GB) -lt [math]::round($sizes.SizeMax / 1GB)) {                                
                                Write-Verbose -Message "Resisizing disk $($partition.DiskNumber) partition $($partition.PartitionNumber) to $($config.DiskSizeGB) GB"                                                               
                                #$partition | Resize-Partition -CimSession $cim -Confirm:$false -Size $sizes.SizeMax -Verbose:$false
                                Invoke-Command -Session $session -ScriptBlock { $args[0] | Resize-Partition -Confirm:$false -Size $args[1] } -ArgumentList @($partition, $sizes.SizeMax) -Verbose:$false 
                            }
                        
                            #$volume = $partition | Get-Volume -CimSession $cim -Verbose:$false
                            $volume = Invoke-Command -Session $session -ScriptBlock { $args[0] | Get-Volume } -ArgumentList $partition -Verbose:$false
                            
                            # Drive letter
                            if ($Volume.DriveLetter -ne $config.VolumeName) {
                                Write-Debug -Message "Setting drive letter to [$($config.VolumeName) ]"
                                #$partition | Set-Partition -CimSession $cim -NewDriveLetter $config.VolumeName -Verbose:$false
                                Invoke-Command -Session $session -ScriptBlock { $args[0] | Set-Partition -NewDriveLetter $args[1] } -ArgumentList @($partition, $config.VolumeName) -Verbose:$false

                            }

                            # Volume label
                            if ($Volume.FileSystemLabel -ne $config.VolumeLabel) {
                                Write-Debug -Message "Setting volume to [$($config.VolumeLabel) ]"
                                $vol = Get-CimInstance -CimSession $cim -ClassName Win32_LogicalDisk -Filter "deviceid='$($Volume.DriveLetter):'" -Verbose:$false
                                $vol | Set-CimInstance -Property @{volumename=$config.VolumeLabel} -Verbose:$false
                                #$volume | Set-Volume -CimSession $cim -NewFileSystemLabel $config.VolumeLabel -Verbose:$false 
                            }                                                   
                        }
                    }
                }
                Remove-CimSession -CimSession $cim -ErrorAction SilentlyContinue
                Remove-PSSession -Session $session -ErrorAction SilentlyContinue
            } else {
                Write-Error -Message 'No valid IP address returned from VM view. Can not test guest disks'
            }  
        } catch {
            Write-Error -Message 'There was a problem configuring the guest disks'
            Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            write-Error $_
        } finally {
            Remove-CimSession -CimSession $cim -ErrorAction SilentlyContinue
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }

    end {
        Write-Debug -Message 'Ending _SetGuestDisks()'
    }
}