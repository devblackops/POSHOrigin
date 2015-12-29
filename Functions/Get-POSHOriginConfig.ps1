function Get-POSHOriginConfig {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline)]
        [string[]]$Path = (Get-Location).Path,

        [switch]$Recurse
    )

    process {
        foreach ($item in $Path) {
            # Load in the configurations
            $item = Resolve-Path $item
            if (Test-Path -Path $item) {
                $configData = @(_LoadConfig -Path $item -Recurse:$Recurse)
                #return $configData
                return _SortByDependency -Objects $configData
            } else {
                Write-Error -Message "Invalid path [$Path]"
            }
        }
    }
}