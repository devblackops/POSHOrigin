function Get-POSHDefault {    
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Configuration = [string]::empty,

        [string]$Path = (_GetOption -Option 'configs_path')
    )

    begin {
        Write-Debug -Message 'Get-POSHDefault(): beginning'
    }

    process {
        $items = @{}

        if ($Configuration -ne [string]::Empty) {
            $configPath = Join-Path -Path $Path -ChildPath "Common\$Configuration.psd1"
        
            Write-Debug "Looking for $configPath"

            if (Test-Path -Path $configPath) {
                #$items = _ParsePsd1 -data ((get-item -Path $configPath ).FullName)
                $items = Invoke-Expression -Command (Get-Content -Path $configPath | Out-String)
            } else {
                Write-Error -Message "Unable to resolve configuration [$configPath]"
            }
            return $items
        } else {
            return $null
        }
    }

    end {
        Write-Debug -Message 'Get-POSHDefault(): ending'
    }
}