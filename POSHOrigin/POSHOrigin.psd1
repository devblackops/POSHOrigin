@{
# Version number of this module.
ModuleVersion = '1.5.4'

# Root module
RootModule = 'POSHOrigin.psm1'

# ID used to uniquely identify this module
GUID = '4eb54734-8088-46bb-bddf-f0eb2e437970'

# Author of this module
Author = 'Brandon Olin'

# Copyright statement for this module
Copyright = '(c) 2015 Brandon Olin. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PowerShell framework for defining and invoking custom DSC resources to provision infrastructure.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

FunctionsToExport = @(
    'Get-POSHDefault',
    'Get-POSHOriginConfig',
    'Get-POSHOriginSecret',
    'Initialize-POSHOrigin',
    'Invoke-POSHOrigin',
    'New-POSHOriginResource'
)

AliasesToExport = @(
    'gpoc',
    'gpos',
    'gpd',
    'ipo',
    'resource'
)

PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Desired State Configuration', 'DSC', 'POSHOrigin', 'Infrastructure as Code', 'IaC'

        # A URL to the license for this module.
        LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/devblackops/POSHOrigin'
    }
}
}