function New-POSHOriginResource {
    param(
        [parameter(mandatory, position = 0)]
        $ResourceType,
        
        [parameter(mandatory, position = 1)]
        $ResourceId,
        
        [parameter(mandatory, position = 2)]
        [hashtable]$Options
    )

    #$stub = _GetBlankResource -Type $ResourceType
    #$merged = _MergeHashtables -primary $Options -secondary $stub -Verbose

    $defaults = @{}
    if ($Options.ContainsKey('Defaults')) {

        # Get parent directory of script that called this function
        # and resolve path to defaults file specified in resource
        $parentDir = (Split-Path -Path $MyInvocation.PSCommandPath -Parent)
        $resolvedPath = Join-Path -Path $parentDir -ChildPath $options.Defaults
        Write-Verbose "Resolved defaults to [$ResolvedPath]"

        # Load defaults file
        $item = Get-Item -Path $resolvedPath
        $defaults = _ParsePsd1 -data ($item.FullName)
    }

    # Merge this resource with the defaults specified
    $merged = _MergeHashtables -Primary $Options -Secondary $defaults -Verbose

    $merged.Name = $ResourceId
    $wrapper = @{
        Name = "$ResourceId"
        Description = $merged.Description
        Driver = $ResourceType
        Options = $merged
    }
    return $wrapper
}