function _ParsePsd1 {
    # http://stackoverflow.com/questions/25408815/how-to-read-powershell-psd1-files-safely
    [outputtype([hashtable])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
        [hashtable]$data = $null
    )
    return $data
}