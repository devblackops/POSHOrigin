#function _GetDefault {
#    [cmdletbinding()]
#    param(
#        [Parameter(Mandatory)]
#        [string]$Option
#    )

#    $repo = (Join-Path -path $env:USERPROFILE -ChildPath '.poshorigin')

#    if (Test-Path -Path $repo -Verbose:$false) {

#        $options = (Join-Path -Path $repo -ChildPath 'options.json')
        
#        if (Test-Path -Path $options ) {
#            $obj = Get-Content -Path $options | ConvertFrom-Json
#            return $obj.$Option
#        } else {
#            Write-Error "Unable to find [$options]"
#        }
#    } else {
#        Write-Error "Undable to find POSHOrigin configuration folder at [$repo]"
#    }
#}