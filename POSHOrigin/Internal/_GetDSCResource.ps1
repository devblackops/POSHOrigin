# Tries to resolve the given DSC resource
function _GetDscResource {
    [cmdletbinding()]
    param(
        [string]$Resource,
        [string]$Module
    )

    $params = @{
        Name = $Resource
        Module = $Module
        ErrorAction =  'SilentlyContinue'
        WarningAction = 'SilentlyContinue'
        Verbose = $false
    }

    $dscResource = Get-DscResource @params
    if (-Not $dscResource) {
        $params.Module = "POSHOrigin_$Module"
        $dscResource = Get-DscResource @params
    }
    if (-Not $dscResource) {
        $params.module = 'POSHOrigin'
        $dscResource = Get-DscResource @params
    }
    
    return $dscResource | Sort -Property Version -Descending | Select -First 1
}
