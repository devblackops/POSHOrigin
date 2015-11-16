function Get-POSHOriginConfig {
    #[cmdletbinding()]
    #param(
    #    #[string]$Path = (_GetOption -Option 'configs_path')
    #    [parameter(mandatory)]
    #    [string]$Path
    #)

    #begin {
    #    Write-Debug -Message 'Get-POSHOriginConfig(): beginning'
    #}

    #process {
    #    $sw = [Diagnostics.Stopwatch]::StartNew()

    #    # Load in the configurations
    #    if (Test-Path -Path $Path) {
    #        $configData = @(_LoadConfig -Path $Path)
    #        Write-Verbose -Message "Total configurations found: $($configData.Count)`n"

    #        $sw.Stop()
    #        Write-Verbose -Message "Command finished in $($sw.Elapsed.Seconds).$($sw.Elapsed.Milliseconds) seconds"

    #        return $configData
    #    } else {
    #        Write-Error -Message "Invalid path [$Path]"
    #    }
    #}

    #end {
    #    Write-Debug -Message 'Get-POSHOriginConfig(): ending'
    #}

    [cmdletbinding()]
    param(
        [parameter(mandatory, ValueFromPipeline)]
        [string[]]$Path,

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