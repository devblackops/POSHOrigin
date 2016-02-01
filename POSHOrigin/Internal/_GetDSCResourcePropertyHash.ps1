
function _GetDSCResourcePropertyHash {
    param(
        $DscResource,
        $Resource
    )

    $hash = @{}

    # Test for 'Invoke.ps1' script in DSC resource module and optionally use it to translate our options into what the
    # DSC resource expects.
    # If there is no 'Invoke.ps1' script or we specified '-NoTranslate' then pass the resource object directly to the DSC resource
    # without any translation. This requires that the correct property names are specificed in the configurations file
    # as they will be passed directly to Invoke-DscResource.
    $invokePath = Join-Path -Path $DscResource.ParentPath -ChildPath 'Invoke.ps1'
    if (Test-Path -Path $invokePath) {
        if (-Not $PSBoundParameters.ContainsKey('NoTranslate')) {
            # Use the 'Invoke.ps1' script to translate our options into what the DSC resource expects.
            Write-Debug -Message "Calling $invokePath to translate properties"
            $hash = & $invokePath -Options $item -Direct:$true
        } else {
            # We are intentially not using the 'Invoke.ps1' script and instead directly passing the object on
            $propNames = $item.options | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$_ -ne 'DependsOn'}
            $propNames | ForEach-Object {
                $hash.Add($_, $item.Options.$_)
            }
            # We have to stip out any properties from the POSHOrigin resource object that the DSC resource does not expect
            $dscResourceProperties = $dscResource.Properties | Select-Object -ExpandProperty Name
            $hashProperties = $hash.GetEnumerator() | Select-Object -ExpandProperty Name
            foreach ($hashProperty in $hashProperties) {
                if ($hashProperty -inotin $dscResourceProperties) {
                    $hash.remove($hashProperty)
                }
            }
        }
    } else {
        #throw "$invokePath not found in DSC module so no property translation could be made. Try using the -NoTranslate switch instead."
        # There is no 'Invoke.ps1' script we we'll just pass on the properties directly to the DSC resource
        # without any translation
        $propNames = $item.options | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        $propNames | ForEach-Object {
            $hash.Add($_, $item.Options.$_)
        }
        # We have to stip out any properties from the POSHOrigin resource object that the DSC resource does not expect
        $dscResourceProperties = $dscResource.Properties | Select-Object -ExpandProperty Name
        $hashProperties = $hash.GetEnumerator() | Select-Object -ExpandProperty Name
        foreach ($hashProperty in $hashProperties) {
            if ($hashProperty -inotin $dscResourceProperties) {
                $hash.remove($hashProperty)
            }
        }
    }

    return $hash
}

