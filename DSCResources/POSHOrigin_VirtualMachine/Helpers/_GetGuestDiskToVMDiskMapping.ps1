function _GetGuestDiskToVMDiskMapping {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DiskSpec
    )

    try {
        $vmView = $vm | Get-View -Verbose:$false -Debug:$false
        $configDisks = ConvertFrom-Json -InputObject $DiskSpec -Verbose:$false
        $vmDisks = @($vm | Get-HardDisk -Verbose:$false -Debug:$false)

        # Create our disk configuration objects that will be passed into the guest OS
        # via VM tools. The Guest will then format the drives based on the instructions
        $diskInstructions = @()
        foreach ($scsiController in ($vmView.Config.Hardware.Device | Where-Object {$_.DeviceInfo.Label -match "SCSI Controller"})) {
            foreach ($diskDevice in ($vmView.Config.Hardware.Device | Where-Object {$_.ControllerKey -eq $scsiController.Key})) {
                        
                $disk = [pscustomobject]@{
                    DiskName = $diskDevice.DeviceInfo.Label
                    DiskSizeGB = $diskDevice.CapacityInKB / 1024 / 1024
                    SCSIController = $scsiController.BusNumber
                    SCSITarget = $diskDevice.UnitNumber
                    VolumeName = $null
                    VolumeLabel = $null
                    BlockSize = $null
                }

                # Find matching disk from configuration
                $matchingDisk = @( $configDisks | Where-Object {$_.Name -eq $disk.DiskName} )

                #Shouldn't happen, but just in case..
                if ($matchingDisk.count -gt 1) {
                    Write-Error -Message "Too many matches: $($matchingDisk | Select-Object Name, SizeGB, Type, Format | Out-String)"
                } elseif($matchingDisk.count -eq 1) {
                    $disk.VolumeName = $matchingDisk.VolumeName
                    $disk.VolumeLabel = $matchingDisk.VolumeLabel
                    $disk.BlockSize = $matchingDisk.BlockSize
                } else {
                    Write-Error -Message 'VM has a disk that is not part of the configuration. Either add this disk to the configuratino or remove the disk from the VM.'
                }
                $diskInstructions += $disk
            }
        }
        return $diskInstructions
    } catch {
        Write-Error -Message 'There was a problem getting the guest disk mapping'
        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        write-Error $_
    }
}