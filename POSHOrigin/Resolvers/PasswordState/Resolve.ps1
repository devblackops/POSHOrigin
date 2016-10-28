[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [psobject]$Options = $null
)

begin {
    Write-Debug -Message $msgs.rslv_passwordstate_begin
}

process {
    # Do something with the passed in options and return a [pscredential]
    if (Get-Module -ListAvailable -Name 'PasswordState' -Verbose:$false) {
        try {
            Import-Module -Name 'PasswordState' -Verbose:$false
            Write-Debug -Message ($msgs.rslv_passwordstate_resolving -f $options.passwordId)

            # PasswordState module expects APIKey to be a pscredential
            $keySecure = $options.credApiKey | ConvertTo-SecureString -AsPlainText -Force
            $apiKeyCred = New-Object System.Management.Automation.PSCredential -ArgumentList ('SecretAPIkey', $keySecure) 
            $params = @{
                ApiKey = $apiKeyCred
                PasswordId = $options.passwordId
                Endpoint = $options.Endpoint
                UseV6Api = $true
                Verbose = $false
            }
            $entry = Get-PasswordStatePassword @params
            if ($null -ne $entry) {
                $cred = $null
                $pass = $entry.Password | ConvertTo-SecureString -AsPlainText -Force

                # Guard against username from Passwordstate being empty
                # We can't create a valid PS credential object without one                 
                if (($entry.Username -eq [string]::Empty) -or ($null -eq $entry.Username)) {
                    Write-Error 'Entry from PasswordState did not have a value for [Username]. Can not create a valid PowerShell credential object without one.'
                    return
                } else {
                    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($entry.UserName, $pass)
                    if ($null -ne $cred) {
                        Write-Debug -Message ($msgs.rslv_passwordstate_got_cred -f $options.passwordId, $entry.Username )
                        return $cred
                    }
                }                
            } else {
                Write-Error -Message ($msgs.rslv_passwordstate_fail -f $options.passwordId, $entry.Username )
            }
        } catch {
            Write-Error -Message ($msgs.rslv_passwordstate_fail -f $options.passwordId, $entry.Username )
            Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            write-Error $_
        }
    } else {
        Write-Error -Message $msgs.rslv_passwordstate_mod_missing
    }
}

end {
    Write-Debug -Message $msgs.rslv_passwordstate_end
}