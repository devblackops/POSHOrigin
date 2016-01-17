[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [psobject]$Options = $null
)

begin {
    Write-Debug -Message $msgs.rslv_pscredential_begin
}

process {
    $keySecure = $options.password | ConvertTo-SecureString -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($options.userName, $keySecure) 
    Write-Verbose -Message ($msgs.rslv_pscredential_got_cred -f $options.userName)
    return $cred
}

end {
    Write-Debug -Message $msgs.rslv_pscredential_end
}