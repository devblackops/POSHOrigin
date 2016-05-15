function _ConvertToDscResourceHash {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'POSHOrigin.Resource' })]
        [pscustomobject[]]$InputObject
    )

    begin {
        
    }

    process {
        foreach ($item in $InputObject) {

            $moduleName = $item.Resource.Split(':')[0]
            $resourceName = $item.Resource.Split(':')[1]
            
            $dscRes = Get-DscResource -name $resourceName -Module $moduleName
            if (-not $dscRes) {
                throw "Unable to find DSC resource [$moduleName] in module [$resourceName]"    
            }
            
            Write-Debug "Processing POSHOrigin resource [$($item.Name)]"

            $hash = @{}

            foreach ($dscProp in $dscRes.Properties) {

                Write-Debug "    Inspecting DSC property [$($dscProp.Name)]"
                
                # Get patching POSHOrigin resource property
                $poProp = ($item.Options.($dscProp.Name))

                # Create a new hashtable of only matching properties
                if ($poProp) {
                        
                    
                    # We have a matching property, now we need to validate the type
                    $dscPropType = $dscProp.PropertyType
                    Write-Debug "        DSC type is $dscPropType"
                    
                    if ($dscProp.Name -eq 'DependsOn' ) {
                        $poPropType = '[string[]]'
                    } else {
                        $poPropType = "[$($poProp.GetType().Name)]"
                    }
                    Write-Debug "        POSHOrigin type is $dscPropType"


                    if ($poPropType -eq $dscPropType) {
                        $hash.($dscProp.Name) = $item.Options.($dscProp.Name)
                    } else {
                        throw "Type mismatch between POSHOrigin property $($dscProp.Name):$poPropType and DSC property $($dscProp.Name):$dscPropType"
                    }
                } else {
                    # If the missing property is mandatory throw error
                    if ($dscProp.IsMandatory) {
                        throw "Unable to find mandatory property [$($dscProp.Name)]"
                    }
                }
            }
            $hash
        }
    }

    end { }
}