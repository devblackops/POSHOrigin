@{
# Script module or binary module file associated with this manifest.
RootModule = 'POSHOrigin_Example.psm1'

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = '6dd5cec1-f537-4517-befe-ff7c7b76d8b4'

# Author of this module
Author = 'Brandon Olin'

# Company or vendor of this module
# CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2015 Brandon Olin. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Example POSHOrigin DSC module.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# DSC resources to export from this module
DscResourcesToExport = @('POSHFolder', 'POSHFile')
}