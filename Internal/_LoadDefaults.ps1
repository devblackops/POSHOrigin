function _LoadDefaults {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path = [string]::empty
    )

    $repoRoot = (_GetOption -Option 'configs_path')

    if (Test-Path -Path $repoRoot) {
        $defaults = @{}
        $defItem = $null
        while($Path -ne $repoRoot) {
            $defPath = (Join-Path -Path $Path -ChildPath "defaults.psd1")
            #Write-Verbose "[$defPath]"
            # Read the local directory defaults.psd1 file if it exists
            if (Test-Path -Path $defPath) {
                Write-Verbose -Message "[$defPath] Processing defaults"
                $defItem = Get-Item -Path $defPath
                $thisDef = _ParsePsd1 -data ($defItem.FullName)
            } else {
                $thisDef = $null
            }

            # Merge this location's defaults with our working defaults
            if ($null -ne $thisDef) {
                Write-Verbose 'Merging defaults'
                #Write-Verbose -Message ($thisDef | ConvertTo-Json | out-string)
                $defaults = _MergeHashtables -Primary $defaults -Secondary $thisDef
            } else {
                # Do nothing
            }

            # Get parent directory
            $parent = Split-Path -Path $Path -Parent
            $Path = $parent
        }
        #Write-Verbose -Message "Reached $parent"
        return $defaults
    } else {
        Write-Error -Message "Unable to resolve 'configs_path' in module options.json"
    }
}