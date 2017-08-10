@{
ModuleVersion = '1.8.1'
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
# 1.8.1 (August 09, 2017)
* Ensure MOF file is always removed (unless told not too) after DSC run.

# 1.8.0 (Unreleased)
  * Add support for using a git repository as the source of a POSHOrigin module
  * When looking for the DSC resource, only return the latest module version
  * Remove legacy code that when resolving secrets, if a secret is called 'guest', to format the UserName property of the credential. This code has been moved to the POSHOrigin_vSphere module
  * Add switch to Invoke-POSHOrigin to PrettyPrint verbose output

# 1.7.1
  - Fix bug in ProtectedData resolver where it was always deleting the source XML file.
    It should only delete the XML file if it downloads it from a URL to a temp file.

# 1.7.0
  - Bug fix with verbose log statement in Initialize-POSHOrigin
  - Add HTTP(s) as possible paths for ProtectedData resolver

# 1.6.0 (May 26, 2016)
  - Add Azure ARM template DSC resource
  - Add `PrettyPrint` switch to Invoke-POSHOriginNEW
  - Fix elapsed time display

## 1.5.11 (May 10, 2016)
  - Fix bug dealing with -WhatIf support in `Invoke-POSHOrigin`
  - Added comment-based help to functions
  - Added about_POSHOrigin_* help documents
  - Modified Get-POSHOriginConfig to accept pipeline input from Get-ChildItem
  - Validate the InputObject to Invoke-POSHOrigin is of type POSHOrigin.Resource

## 1.5.10 (April 17, 2016)
  - Add new ```secret``` alias to ```Get-POSHOriginSecret```
  - Remove some old code
  - Change LCM configuration from ```ApplyAndMonitor``` to ```ApplyOnly```

## 1.5.9 (Feb 24, 2016)
  - Change LCM inititialization to use v5 syntax

## 1.5.9 (Feb 2, 2016)
  - Added new credential resolver 'ProtectedData'
  - Added experimental cmdlet Invoke-POSHOriginConfigNew (alias: iponew) that
    will invoke DSC resources directly using Invoke-DscResource rather than
    compiling and appliying a MOF using Start-DscConfiguration

## 1.5.8 (Jan 18, 2016)
  - Added experimental support for resuable modules

## 1.5.7 (Jan 16, 2016)
  - Added en-US localization
"
    }
}
}