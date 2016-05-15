function New-POSHOriginResource {
    param(
        [parameter(mandatory, position = 0)]
        $ResourceType,
        
        [parameter(mandatory, position = 1)]
        $Name,
        
        [parameter(mandatory, position = 2)]
        [hashtable]$Options
    )

    $fullName = "[" + $ResourceType.Split(':')[1] + "]" + $Name

    Write-Verbose -Message "    Creating resource $fullName"

    if (-not $resourceCache.ContainsKey($fullName)) {
        $script:resourceCache.Add($fullName, $fullName)

        $defaults = @{}
        if ($Options.ContainsKey('Defaults')) {

            # Get parent directory of script that called this function
            # and resolve path to defaults file specified in resource
            $parentDir = Split-Path -Path $MyInvocation.PSCommandPath -Parent
            $resolvedPath = Join-Path -Path $parentDir -ChildPath $options.Defaults
            $resolvedPath = Resolve-Path -Path $resolvedPath
            $resourceName = "[$ResourceType]$Name"
            Write-Verbose -Message ("      " + $msgs.npor_resolved_defaults -f $resourceName, $resolvedPath)

            # Load defaults file
            $item = Get-Item -Path $resolvedPath
            $defaults = _ParsePsd1 -data ($item.FullName)
        }

        # Merge this resource with the defaults specified
        $merged = _MergeHashtables -Primary $Options -Secondary $defaults -Verbose

        # Strip out the 'defaults' parameter
        $merged.Remove('defaults')

        # If 'DependsOn' is a single string, change it to a string[]
        if ($merged.DependsOn -and $merged.DependsOn -is [string]) {
            $t = $merged.DependsOn
            $merged.DependsOn = @()
            $merged.DependsOn += $t
        }

        # IF 'DependsOn' is an empty string, make it null
        if ($merged.DependsOn -eq [string]::Empty) {
            $merged.DependsOn = @()
        }

        # Add an empty 'Dependson' parameter is none is specified
        if (-Not ($merged.GetEnumerator() | Select-Object -ExpandProperty Name) -icontains 'DependsOn') {
            $merged.DependsOn = @()
        }
    
        # Set the 'Name' parameter to the name given in the resource declaration
        # only if the resource options don't explicitly have a name parameter
        if (-Not $merged.ContainsKey('Name')) {
            $merged.Name = $Name
        }

        $wrapper = @{
            Name = $Name
            FullName = $fullName
            Description = $merged.Description
            Resource = $ResourceType
            DependsOn = $merged.DependsOn
            Options = $merged
        }
        return $wrapper
    } else {
        Write-Warning -Message "Resource $fullName is already defined and will not be defined again"
    }
}