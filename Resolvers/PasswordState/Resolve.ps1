[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [psobject]$Options = $null
)

begin {
    Write-Debug -Message 'PasswordState resolver: beginning'
}

process {
    # Do something with the passed in options
    # and return a [pscredential]
    if ($null -ne $Options) {

        if (Get-Module -ListAvailable -Name 'PasswordState' -Verbose:$false) {
            try {
                Import-Module -Name 'PasswordState' -Verbose:$false

                Write-Debug -Message "Resolving credential for $($options.passwordId)"

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
                    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($entry.UserName, $pass)    
                    if ($null -ne $cred) {
                        write-verbose "Got credential for [$($options.passwordId)] - [$($entry.Username)) - ********]"
                        return $cred
                    }
                } else {
                    Write-Error -Message "Unable to resolve credential for password Id [$($options.passwordId)] and API key [$($options.credApiKey)]"
                }    
            } catch {
                Write-Error -Message "Unable to resolve credential for password Id [$($options.passwordId)] and API key [$($options.credApiKey)]"
                Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                write-Error $_
            }
        } else {
            Write-Error -Message 'Unable to find required module [PasswordState] on system'
        }
    } else {
        return $null
    }
}

end {    
    Write-Debug -Message 'PasswordState resolver: ending'
}