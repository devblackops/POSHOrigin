## 1.5.11 (May 10, 2016)
  - Fix bug dealing with -WhatIf support in `Invoke-POSHOrigin`

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
[Pester](https://github.com/pester/Pester/blob/master/CHANGELOG.md) file.