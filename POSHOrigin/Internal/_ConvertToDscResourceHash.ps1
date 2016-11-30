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
            
            $dscRes = _GetDscResource -Module $moduleName -Resource $resourceName
            
            if (-not $dscRes) {
                throw "Unable to find DSC resource [$moduleName] in module [$resourceName]"    
            }
            
            Write-Debug "Processing POSHOrigin resource [$($item.Name)]"

            $hash = @{}

            foreach ($dscProp in $dscRes.Properties) {

                Write-Debug "    Inspecting DSC property [$($dscProp.Name)]"
                
                # Get patching POSHOrigin resource property
                $poProp = ($item.Options.($dscProp.Name))
                #$poProp = $item.Options | Get-Member -MemberType NoteProperty | where Name -eq $dscProp.Name

                # Create a new hashtable of only matching properties
                if ($null -ne $poProp) {                
                    
                    # We have a matching property, now we need to validate the type
                    $dscPropType = $dscProp.PropertyType
                                        
                    Write-Debug "        DSC type is $dscPropType"
                    
                    if ($dscProp.Name -eq 'DependsOn' ) {
                        $poPropType = '[string[]]'
                    } else {
                        $poPropType = "[$($poProp.GetType().Name)]"
                    }
                    if ($poPropType -eq '[Boolean]') {
                        $poPropType = '[bool]'
                    }
                    Write-Debug "        POSHOrigin type is $poPropType"
                   

                    if ($poPropType -eq $dscPropType) {
                        $hash.($dscProp.Name) = $item.Options.($dscProp.Name)
                    } else {
                        
                        # See if DSC type is string and POSHOrigin type is an object or array of objects
                        # if so, let's convert the POSHOrigin property to a JSON string so it can be                         
                        if ($dscPropType -eq '[string]' -and ($poPropType -eq '[pscustomobject]' -or $poPropType -eq '[object[]]')) {
                            write-verbose "Converting $($dscProp.Name) to JSON..."
                            $hash.($dscProp.Name) = ($item.Options.($dscProp.Name) | ConvertTo-Json -Depth 100)
                        } else {
                            throw "Type mismatch between POSHOrigin property $($dscProp.Name):$poPropType and DSC property $($dscProp.Name):$dscPropType"   
                        }
                    }
                } else {
                    # If the missing property is mandatory throw error
                    if ($dscProp.IsMandatory) {
                        throw "Unable to find mandatory property [$($dscProp.Name)]"
                    }
                }
            }
            #write-host ($hash | fl * | out-string)
            $hash
        }
    }

    end { }
}