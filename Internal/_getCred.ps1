function _getCred{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Apikey,

        [Parameter(Mandatory)]
        [int]$PasswordId,

        [Parameter(Mandatory)]
        [string]$Endpoint
    )

    Import-Module -Name 'PasswordState' -Verbose:$false
    
    # PasswordState module expects APIKey to be a pscredential
    $keySecure = $Apikey | ConvertTo-SecureString -AsPlainText -Force
    $apiKeyCred = New-Object System.Management.Automation.PSCredential -ArgumentList ('SecretAPIkey', $keySecure)  

    try {
        $cred = $null
        $entry = Get-PasswordStatePassword -Apikey $apiKeyCred -PasswordId $PasswordId -Endpoint $Endpoint
        if ($entry -ne $null) {
            $pass = $entry.Password | ConvertTo-SecureString -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($entry.UserName, $pass)    
            if ($cred -ne $null) {
                write-verbose "Got credential for [$PasswordId] - [$($entry.Username)) - ********]"                
                return $cred
            }
        } else {
            Write-Error -Message "Unable to resolve credential for password Id [ $PasswordId ] and API key [ $Apikey ]"
        }    
    } catch {
        Write-Error -Message "Unable to resolve credential for password Id [ $PasswordId ] and API key [ $Apikey ]"
        Write-Error "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        write-Error $_        
    }    
}