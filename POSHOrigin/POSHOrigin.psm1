#Requires -Version 5.0
#Requires -RunAsAdministrator

# Messages
$msgs = Import-LocalizedData -FileName messages.psd1

# Our credential cache
$script:credentialCache = @{}

# cache of modules to process
$script:modulesToProcess = @{}

# Cache of git-based modules we've processed
$script:gitModulesProcessed = @{}

# cache of resource names 
$script:resourceCache = @{}

# Load functions
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path
"$moduleRoot\Functions\*.ps1", "$moduleRoot\Internal\*.ps1" |
    Resolve-Path |
    Where-Object { -not ($_.ProviderPath.ToLower().Contains(".tests.")) } |
    ForEach-Object { . $_.ProviderPath }

# This gets executed when the module is removed from the session
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-Variable -Name credentialCache -Scope Script
    Remove-Variable -Name modulesToProcess -Scope Script
    Remove-Variable -Name gitModulesProcessed -Scope Script
    Remove-Variable -Name resourceCache -Scope Script         
}  

#Export-ModuleMember -Function *POSH*
New-Alias -Name gpoc -Value Get-POSHOriginConfig
New-Alias -Name secret -Value Get-POSHOriginSecret
New-Alias -Name gpos -Value Get-POSHOriginSecret
New-Alias -Name gpd -Value Get-POSHDefault
New-Alias -Name ipo -Value Invoke-POSHOrigin
New-Alias -Name iponew -Value Invoke-POSHOriginNEW
New-Alias -Name resource -Value New-POSHOriginResource
New-Alias -Name module -Value New-POSHOriginResourceFromModule
