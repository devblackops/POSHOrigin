<#
    This script expects to be passed a psobject with all the needed properties
    in order to invoke a 'VirtualMachine' DSC resource.
#>
[cmdletbinding()]
param(
    [parameter(mandatory)]
    [psobject]$Options,

    [bool]$Direct = $false
)

# Ensure we have a valid 'ensure' property
if ($null -eq $Options.options.Ensure) {
    $Options.Options | Add-Member -MemberType NoteProperty -Name Ensure -Value 'Present' -Force
}

# Get the resource type
$type = $Options.Resource.split(':')[1]

# Get the resource type
$type = $Options.Resource.split(':')[1]

switch ($type) {
    'poshfile' {
        if ($Direct) {
            $hash = @{
                Name = $Options.Name
                Ensure = $Options.options.Ensure
                Path = $Options.options.Path
            }
            if ($Options.options.contents) {
                $hash.contents = $Options.options.contents
            }
            return $hash
        } else {
            # Dashes (-) are not allowed in DSC configurations names
            $itemName = $Options.Name.Replace('-', '_')
            $confName = "$type" + '_' + $itemName
            Write-Verbose -Message "Returning configuration function for resource: $confName"

            Configuration $confName {
                Param (
                    [psobject]$ResourceOptions
                )

                Import-DscResource -Name POSHFile -ModuleName POSHOrigin

                POSHFolder $ResourceOptions.Name {
                    Ensure = $ResourceOptions.options.Ensure
                    Name = $ResourceOptions.Name
                    Path = $ResourceOptions.Name
                }
            }
        }
    }
}