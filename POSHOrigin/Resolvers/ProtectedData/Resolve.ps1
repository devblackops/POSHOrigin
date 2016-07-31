[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [psobject]$Options = $null
)

begin {
    Write-Debug -Message $msgs.rslv_protecteddata_begin
}

process {
    if (Get-Module -ListAvailable -Name 'ProtectedData' -Verbose:$false) {
        Import-Module -Name 'ProtectedData' -Verbose:$false
        $xmlPath = $Options.Path
        $output = $null

        if (($xmlPath.StartsWith('http://')) -or ($xmlPath.StartsWith('https://'))) {
            $filename = $xmlPath.SubString($xmlPath.LastIndexOf('/') + 1)
            $output = "$($ENV:Temp)\$filename"
            Invoke-WebRequest -Uri $xmlPath -OutFile $output
            $xmlPath = $output
        }
        
        if (Test-Path -Path $xmlPath) {
            try {
                $encypted = Import-Clixml -Path $xmlPath -Verbose:$false

                if ($Options.Password) {
                    $secPassword = $Options.Password | ConvertTo-SecureString -AsPlainText -Force
                    $decrypted = $encypted | Unprotect-Data -Password $secPassword
                } elseIf ($Options.Certificate) {
                    $decrypted = $encypted | Unprotect-Data -Certificate $Options.Certificate
                } else {
                    throw 'Unable to decrypt credential without a valid password or certificate'
                }

                if ($decrypted) {
                    Write-Debug -Message ($msgs.rslv_protecteddata_got_cred -f $xmlPath)
                    Remove-Item -Path $xmlPath -Force
                    return $decrypted
                } else {
                    throw 'Unable to decrypt credential with options provided'
                }
            } catch {
                Remove-Item -Path $xmlPath -Force
                Write-Debug -Message ($msgs.rslv_passwordstate_fail -f $options.passwordId, $entry.Username )
                Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                write-Error $_
            }
        } else {
            throw "Unable to find file $($xmlPath)"
        }
    }
}

end {
    Write-Debug -Message $msgs.rslv_protecteddata_end
}