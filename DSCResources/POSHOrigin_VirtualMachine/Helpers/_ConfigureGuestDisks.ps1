function _ConfigureGuestDisks {
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

    try {
        $mapping = _GetGuestDiskToVMDiskMapping -vm $vm -DiskSpec $DiskSpec
        _SetGuestDisks -vm $vm -Mapping $mapping -Credential $Credential
    } catch {
        Write-Error -Message 'There was a problem configuring the guest disks'
        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        write-Error -Exception $_
    }
}