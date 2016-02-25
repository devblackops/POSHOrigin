# Tries to resolve the given DSC resource
function _GetDscResource {
    param(
        [string]$Resource,
        [string]$Module
    )

    $dscResource = Get-DscResource -Name $Resource -Module $Module -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose:$false
    if (-Not $dscResource) {
        $dscResource = Get-DscResource -Name $Resource -Module "POSHOrigin_$Module" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose:$false
    }
    if (-Not $dscResource) {
        $dscResource = Get-DscResource -Name $Resource -Module 'POSHOrigin' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose:$false
    }
    if ($dscResource) {
        return $dscResource
    }
}
