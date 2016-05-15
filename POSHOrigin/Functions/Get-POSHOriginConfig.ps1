function Get-POSHOriginConfig {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline)]
        [string[]]$Path = (Get-Location).Path,

        [switch]$Recurse
    )

    begin {
        $script:credentialCache = @{}
        $script:modulesToProcess = @{}
        $script:resourceCache = @{}
    }

    process {
        foreach ($item in $Path) {
            # Load in the configurations
            $item = Resolve-Path $item
            if (Test-Path -Path $item) {
                $configData = @(_LoadConfig -Path $item -Recurse:$Recurse) | _SortByDependency
                Write-Verbose -Message ([string]::Empty)
                Write-Verbose -Message ("Created $($configData.Count) resource objects")
                return $configData
            } else {
                Write-Error -Message ($msgs.invalid_path -f $path)
            }
        }
    }

    end {
        $script:credentialCache = @{}
        $script:modulesToProcess = @{}
        $script:resourceCache = @{}
    }
}