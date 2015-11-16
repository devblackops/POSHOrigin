function _TestGuestDisks {
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
        Write-Debug -Message '_TestGuestDisks() starting'
    }

    process {

        $pass = $true

        try {
            $mapping = _GetGuestDiskToVMDiskMapping -vm $vm -DiskSpec $DiskSpec

            $t = Get-VM -Id $vm.Id -Verbose:$false -Debug:$false
            $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1

            if ($null -ne $ip -and $ip -ne [string]::Empty) {
            
                $cim = New-CimSession -ComputerName $ip -Credential $Credential -Verbose:$false
                $session = New-PSSession -ComputerName $ip -Credential $credential -Verbose:$false
                $wmiDisks = Get-CimInstance -CimSession $cim -ClassName Win32_DiskDrive -Verbose:$false
            
                $disks = Invoke-Command -Session $session -ScriptBlock { Get-Disk }
                #$disks = Get-Disk -CimSession $cim -Verbose:$false

                # Compare the mapping to what is configured
                foreach($config in $mapping) {
                
                    # Does this config exist?
                    $wmiMatch = $wmiDisks | Where-Object {($_.SCSIBus -eq $config.SCSIController) -and ($_.SCSITargetId -eq $config.SCSITarget)} | Select-Object -First 1

                    if ($null -ne $wmiMatch) {
                    
                        $disk = $disks | Where-Object {$_.SerialNumber -eq $wmiMatch.SerialNumber} | Select-Object -First 1

                        if ($null -ne $disk) {

                            Write-Debug -Message "Testing guest disk configuration [$($config.DiskName)]"

                            $diskSize = $disk.Size / 1GB

                            #$partition = $disk | Get-Partition -CimSession $cim -Verbose:$false | Where-Object {$_.Type -ne 'Reserved' -and $_.IsSystem -eq $false} | Select-Object -First 1
                            $partition = Invoke-Command -Session $session -ScriptBlock { $args[0] | Get-Partition -Verbose:$false | Where-Object {$_.Type -ne 'Reserved' -and $_.Type -ne 'Unknown' -and $_.IsSystem -eq $false} | Select-Object -Last 1 } -ArgumentList $disk
                            
                            #write-verbose ($partition | fl * | out-string)

                            if ($null -ne $partition) {
                                #$sizes = $partition | Get-PartitionSupportedSize -CimSession $cim
                                $sizes = Invoke-Command -Session $session -ScriptBlock { $args[0] | Get-PartitionSupportedSize } -ArgumentList $partition

                                # The max partition size is greater than the current partition size
                                if ( [math]::round($partition.Size / 1GB) -lt [math]::round($sizes.SizeMax / 1GB)) {
                                    $partSize = [Math]::Round($partition.Size / 1GB)
                                    Write-Verbose -Message "Disk $($disk.Number) does not match configuration: $partSize GB <> $($config.DiskSizeGB) GB"
                                    $pass = $false
                                }

                                #$volume = $partition | Get-Volume -CimSession $cim -Verbose:$false | Select-Object -First 1
                                $volume = Invoke-Command -Session $session -ScriptBlock { $args[0] | Get-Volume -Verbose:$false | Select-Object -last 1 } -ArgumentList $partition
                                #write-verbose ($volume | fl * | out-string)
                            
                                # Drive letter
                                if ($volume.DriveLetter -ne $config.VolumeName) {
                                    Write-Verbose -Message "Volume [ $($volume.DriveLetter) ] does not match configuration [ $($config.VolumeName) ]"
                                    $pass = $false
                                }

                                # Volume label
                                if ($volume.FileSystemLabel -ne $config.VolumeLabel) {
                                    Write-Verbose -Message "Volume label [ $($Volume.FileSystemLabel) ] does not match configuration [ $($config.VolumeLabel) ]"
                                    $pass = $false
                                }
                            } else {
                                Write-Verbose -Message "Could not find partition for disk $($config.SCSIController):$($config.SCSITarget)"
                                $pass = $false
                            }
                        } else {
                            Write-Verbose -Message 'Could not find matching disk'
                            $pass = $false
                        }
                    } else {                    
                        Write-Verbose -Message "Could not find disk $($config.SCSIController):$($config.SCSITarget)"
                        $pass = $false
                    }
                }
                Remove-CimSession -CimSession $cim -ErrorAction SilentlyContinue
                Remove-PSSession -Session $session -ErrorAction SilentlyContinue                
            } else {
                Write-Error -Message 'No valid IP address returned from VM view. Can not test guest disks'
                $pass = $true
            }
            return $pass
        } catch {            
            Write-Error -Message 'There was a problem testing the guest disks'
            Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            write-Error -Exception $_
        } finally {
            Remove-CimSession -CimSession $cim -ErrorAction SilentlyContinue
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }

        return $pass
    }

    end {
        Write-Debug -Message '_TestGuestDisks() ending'
    }
}