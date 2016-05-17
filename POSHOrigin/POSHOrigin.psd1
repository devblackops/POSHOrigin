@{
ModuleVersion = '1.5.11'
RootModule = 'POSHOrigin.psm1'
GUID = '4eb54734-8088-46bb-bddf-f0eb2e437970'
Author = 'Brandon Olin'
Copyright = '(c) 2016 Brandon Olin. All rights reserved.'
Description = 'PowerShell framework for defining and invoking custom DSC resources to provision infrastructure.'
PowerShellVersion = '5.0'
CLRVersion = '4.0'
FunctionsToExport = @(
    'Get-POSHDefault',
    'Get-POSHOriginConfig',
    'Get-POSHOriginSecret',
    'Initialize-POSHOrigin',
    'Invoke-POSHOrigin',
    'Invoke-POSHOriginNew',
    'New-POSHOriginResource',
    'New-POSHOriginResourceFromModule'
)
AliasesToExport = @(
    'gpoc',
    'gpos',
    'gpd',
    'ipo',
    'iponew',
    'secret'
    'resource',
    'module'
)
DscResourcesToExport = @(
    'POSHFile',
    'POSHFolder'
)
#TypesToProcess = @('POSHOrigin.Resource.ps1xml')
#FormatsToProcess = @('POSHOrigin.Resource.format.ps1xml')
PrivateData = @{
    PSData = @{
        Tags = 'DesiredStateConfiguration', 'DSC', 'POSHOrigin', 'InfrastructureasCode', 'IaC'
        LicenseUri = 'https://raw.githubusercontent.com/devblackops/POSHOrigin/master/LICENSE'
        ProjectUri = 'https://github.com/devblackops/POSHOrigin'
        IconUri = 'https://raw.githubusercontent.com/devblackops/POSHOrigin/master/Media/POSHOrigin_256.png'
        ReleaseNotes = "
- Fix bug dealing with -WhatIf support in Invoke-POSHOrigin
- Added comment-based help to functions
- Added about_POSHOrigin_* help documents
- Modified Get-POSHOriginConfig to accept pipeline input from Get-ChildItem
- Validate the InputObject to Invoke-POSHOrigin is of type POSHOrigin.Resource"
    }
}
}