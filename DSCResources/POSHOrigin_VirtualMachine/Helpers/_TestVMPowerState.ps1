function _TestVMPowerState {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [bool]$PowerOnAfterCreation
    )

    if (($PowerOnAfterCreation -eq $true) -and ($vm.PowerState -eq 'PoweredOn')) {
        return $true
    } else {        
        return $false
    }
}