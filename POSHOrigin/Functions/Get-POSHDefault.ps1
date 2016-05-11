
function Get-POSHDefault {
    <#
        .SYNOPSIS
            Retrieves a POSHOrigin configuration snippet
        .DESCRIPTION
            Retrieves a POSHOrigin configuration snippet as a hashtable that will be merged with the calling configuration resource.
            Useful for re-using partial configuration options across resources. Configuration snippets are hashtables saved with a .psd1 file
            extension.
        .PARAMETER Configuration
            Name of configuration snippet to retrieve. Do not include the file extension (.psd1)
        .PARAMETER Path
            Path to folder that holds the configuration snippets. Default value is retrieved from the configs_path parameter stored in
            $env:USERPROFILE.poshorigin\options.json
        .EXAMPLE
            Use the value from the configuration snippet 'standard_disks' in the [disks] parameter.
            
            resource 'POSHOrigin_vSphere:VM' 'VM01' @{
                ensure = 'present'
                description = 'Test VM'
                ###
                # Other options omitted for brevity
                ###
                disks = Get-POSHDefault 'standard_disks'
            }
    #>
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