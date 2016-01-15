#Requires -Version 5.0
#Requires -RunAsAdministrator

$script:credentialCache = @{}

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

# Load functions
"$moduleRoot\Functions\*.ps1", "$moduleRoot\Internal\*.ps1" |
    Resolve-Path |
    Where-Object { -not ($_.ProviderPath.ToLower().Contains(".tests.")) } |
    ForEach-Object { . $_.ProviderPath }

#Export-ModuleMember -Function *POSH*
New-Alias -Name gpoc -Value Get-POSHOriginConfig
New-Alias -Name gpos -Value Get-POSHOriginSecret
New-Alias -Name gpd -Value Get-POSHDefault
New-Alias -Name ipo -Value Invoke-POSHOrigin
New-Alias -Name iponew -Value Invoke-POSHOriginNEW
New-Alias -Name resource -Value New-POSHOriginResource
#Export-ModuleMember -Alias gpoc
#Export-ModuleMember -Alias gpos
#Export-ModuleMember -Alias gpd
#Export-ModuleMember -Alias ipo
#Export-ModuleMember -Alias iponew
#Export-ModuleMember -Alias resource
