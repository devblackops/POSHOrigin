function Get-POSHOriginConfig {
    [cmdletbinding()]
    param(
        [parameter(mandatory, ValueFromPipeline)]
        [string[]]$Path = (Get-Location).Path,

        [switch]$Recurse
    )

    process {
        foreach ($item in $Path) {
            # Load in the configurations
            $item = Resolve-Path $item
            if (Test-Path -Path $item) {
                $configData = @(_LoadConfigNEW -Path $item -Recurse:$Recurse)
                return $configData
            } else {
                Write-Error -Message "Invalid path [$Path]"
            }
        }
    }
}