function Get-POSHDefault {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Configuration = [string]::empty,

        [string]$Path = (_GetOption -Option 'configs_path')
    )

    begin {
        Write-Debug -Message $msgs.gpd_begin
    }

    process {
        $items = @{}

        if ($Configuration -ne [string]::Empty) {
            $configPath = Join-Path -Path $Path -ChildPath "Common\$Configuration.psd1"

            Write-Debug -Message ($msgs.gpd_looking_for_config -f $configPath)

            if (Test-Path -Path $configPath) {
                #$items = _ParsePsd1 -data ((get-item -Path $configPath ).FullName)
                $items = Invoke-Expression -Command (Get-Content -Path $configPath | Out-String)
            } else {
                Write-Error -Message ($msgs.gpd_config_not_found -f $configPath)
            }
            return $items
        } else {
            return $null
        }
    }

    end {
        Write-Debug -Message $msgs.gpd_end
    }
}