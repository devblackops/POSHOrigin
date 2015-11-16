function _TestVMCPU {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [int]$TotalvCPU,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [int]$CoresPerSocket
    )

    # VM matches CPU
    if (($vm.extensiondata.config.hardware.numcpu -ne $TotalvCPU) -or ($vm.extensiondata.config.hardware.numcorespersocket -ne $CoresPerSocket)) {
        return $false
    } else {
        return $true
    }
}