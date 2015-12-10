function _SetVMDisks {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DiskSpec
    )

    $configDisks = ConvertFrom-Json -InputObject $DiskSpec -Verbose:$false
    $vmDisks = @($vm | Get-HardDisk -Verbose:$false)
    Write-Debug -Message "Configuration disk count: $($configDisks.Count)"
    Write-Debug -Message "VM disk count: $($vmDisks.Count)"

    $changed = $false
    foreach ($disk in $configDisks) {

        $vmDisk = $vmDisks | Where-Object {$_.Name.ToLower() -eq $disk.Name.ToLower() }

        # Add VM disk
        if ($vmDisk -eq $null) {
            try {
                $datastore = $vm | Get-Datastore -Verbose:$false | Select-Object -first 1
                Write-Verbose -Message "Creating disk [$($disk.Name) - $($disk.SizeGB) GB] on datastore [$($datastore.Name)]"
                New-Harddisk -vm $vm -capacitygb $disk.SizeGB -DiskType $disk.Type -storageformat $disk.format -datastore $datastore -verbose:$false -confirm:$false
                $changed = $true
            } catch {
                Write-Error -Message 'There was a problem creating the disk.'
                Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                Write-Error -Exception $_
            }
        } else {
            # Resize VM disk
            if ($vmDisk.CapacityGB -lt $disk.SizeGB) {
                Write-Verbose "Resizing disk [$($vmDisk.Name) to $($disk.SizeGB) GB"
                $vmDisk | Set-Harddisk -CapacityGB $disk.SizeGB -Verbose:$false -Confirm:$false
                $changed = $true
            }
        }
    }

    return $changed
}