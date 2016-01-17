function _GetOption {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Option = [string]::empty,

        [string]$repo = (Join-Path -path $env:USERPROFILE -ChildPath '.poshorigin')
    )

    if (Test-Path -Path $repo -Verbose:$false) {
        $options = (Join-Path -Path $repo -ChildPath 'options.json')
        if (Test-Path -Path $options ) {
            $obj = Get-Content -Path $options | ConvertFrom-Json
            return $obj.$Option
        } else {
            Write-Error -Message ($msgs.go_file_not_found -f $options)
        }
    } else {
        Write-Error -Message ($msgs.go_config_folder_not_found -f $repo)
    }
}