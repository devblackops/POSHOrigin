function _TestVMDisks {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DiskSpec
    )

    begin {
        Write-Debug -Message '_TestVMDisks() starting'
    }

    process {
               
        try {
            $configDisks = ConvertFrom-Json -InputObject $DiskSpec -Verbose:$false
            $vmDisks = @($vm | Get-HardDisk -Verbose:$false -Debug:$false)
            Write-Debug -Message "Configuration disk count: $(@($configDisks).Count)"
            Write-Debug -Message "VM disk count: $(@($vmDisks).Count)"

            if ( @($configDisks).Count -ne @($vmDisks).Count) {
                Write-Verbose -Message 'Disk count does not match configuration'
                $pass = $false
                return $pass
            }

            foreach ($disk in $configDisks) {
                Write-Debug -Message "Validating VM disk [$($disk.Name)]"

                $vmDisk = $vmDisks | Where-Object {$_.Name.ToLower() -eq $disk.Name.ToLower() }
                if ($null -eq $vmDisk) {
                    Write-Verbose -Message "Disk [$($disk.Name)] does not exist on VM"
                    return $false
                }

                $vmDiskCap = [system.math]::round($vmDisk.CapacityGB, 0)
                if ($vmDiskCap -ne $disk.SizeGB) {
                    Write-Verbose -Message "Disk [$($disk.Name)] does not match configured size"
                    return $false
                }

                $vmDiskStorageFormat = ''
                if ($null -ne $vmDisk.StorageFormat) {
                    $vmDiskStorageFormat = $vmDisk.StorageFormat
                }
                $diskStorageFormat = ''
                if ($null -ne $disk.Format) {
                    $diskStorageFormat = $disk.Format
                }
                if ($vmDiskStorageFormat.ToString().ToLower() -ne $diskStorageFormat.ToLower()) {
                    Write-Verbose -Message "Disk [$($disk.Name)] does not match configured format"
                    return $false
                }

                if ($vmDisk.DiskType.ToString().ToLower() -ne $disk.Type.ToLower()) {
                    Write-Verbose -Message "Disk [$($disk.Name)] does not match configured type"
                    return $false
                }
            }
            return $true
        } catch {
            Write-Error -Message 'There was a problem testing the disks.'
            Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            Write-Error $_
        }
    }

    end {
        Write-Debug -Message '_TestVMDisks() ending'
    }
}