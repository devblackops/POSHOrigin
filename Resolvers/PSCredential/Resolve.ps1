[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [psobject]$Options = $null
)

begin {
    Write-Debug -Message 'PSCredential resolver: beginning'
}

process {
    $keySecure = $options.password | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($options.userName, $keySecure) 
    write-verbose "Got credential for [$($options.userName)] - ********]"
    return $cred
}

end {
    Write-Debug -Message 'PSCredential resolver: ending'
}