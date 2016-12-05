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

## Previous
This changelog is inspired by the
[Pester](https://github.com/pester/Pester/blob/master/CHANGELOG.md) file