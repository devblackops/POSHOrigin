@{
ModuleVersion = '1.5.9'
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
    'New-POSHOriginResourceFromModule',
    'Write-POSHScreen'
)
AliasesToExport = @(
    'gpoc',
    'gpos',
    'gpd',
    'ipo',
    'iponew',
    'resource',
    'module',
    'wps'
)
DscResourcesToExport = @(
    'POSHFile',
    'POSHFolder'
)
TypesToProcess = @('POSHOrigin.Resource.ps1xml')
FormatsToProcess = @('POSHOrigin.Resource.format.ps1xml')
PrivateData = @{
    PSData = @{
        Tags = 'Desired State Configuration', 'DSC', 'POSHOrigin', 'Infrastructure as Code', 'IaC'
        LicenseUri = 'https://raw.githubusercontent.com/devblackops/POSHOrigin/master/LICENSE'
        ProjectUri = 'https://github.com/devblackops/POSHOrigin'
        IconUri = 'https://raw.githubusercontent.com/devblackops/POSHOrigin/master/Media/POSHOrigin_256.png'
        ReleaseNotes = 'Added new credential resolver using ProtectedData module.'
    }
}
}