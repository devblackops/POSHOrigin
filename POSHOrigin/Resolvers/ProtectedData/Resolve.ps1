[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [psobject]$Options = $null
)

begin {
    Write-Debug -Message 'ProtectedData resolver: beginning'
}

process {
    
}

end {
    Write-Debug -Message 'ProtectedData resolver: ending'
}