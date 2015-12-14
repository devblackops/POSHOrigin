#function Invoke-POSHOriginNEW {
#    [cmdletbinding()]
#    param(
#        [parameter(Mandatory,ValueFromPipeline)]
#        [hashtable[]]$Resource,

#        [switch]$WhatIf
#    )

#    process {
#        $results = @()

#        foreach ($item in $Resource) {

#            # Derive the resource type and module from the resource properties
#            $mod = $item.Driver.Split(':')[0]
#            $resourceName = $item.Driver.Split(':')[1]
#            $DscModule = "POSHOrigin_$mod"

#            # Construct resource parameters
#            if ($null -eq $item.Options.Ensure) {
#                $item.Options.Ensure = 'Present'
#            }
#            $params = @{
#                Name = $resourceName
#                ModuleName = $DscModule
#                Property = $item.Options
#                #Property = $resourceOptions
#            }
            
#            if ($PSBoundParameters.ContainsKey('WhatIf')) {
#                $testResult = Invoke-DscResource -Method Test @params -Verbose:$false
#                $result = "" | Select Resource, InDesiredState
#                $result.Resource = Invoke-DscResource -Method Get @params -Verbose:$false
#                $result.InDesiredState = $testResult.InDesiredState
#                $results += $result
#                #return $testResult
#            } else {
#                $pass = Invoke-DscResource -Method Test @params -Verbose:$false
#                if (-Not $pass) {
#                    Invoke-DscResource -Method Set @params -Verbose:$false
#                    $setResult = Invoke-DscResource -Method Get @params -Verbose:$false
#                    $results += $setResult
#                } 
#            }
#        }
#        $results
#    }
#}