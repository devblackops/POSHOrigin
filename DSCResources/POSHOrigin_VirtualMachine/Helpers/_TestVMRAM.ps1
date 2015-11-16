function _TestVMRAM {
    [cmdletbinding()]
    param(
        $VM,
        [int]$RAM
    )

    # VM matches memory
    if ($VM.MemoryGB -ne $RAM) {        
        return $false
    } else {
        return $true
    }
}