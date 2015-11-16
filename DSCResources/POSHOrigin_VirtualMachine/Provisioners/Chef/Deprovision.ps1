[cmdletbinding()]
param(
    [parameter(mandatory)]
    $Options
)

begin {
    Write-Debug -Message 'Chef deprovisioner: beginning'
}

process {
    try {
        Write-Verbose -Message 'Removing Chef client...'
    } catch {
        Write-Error -Message 'There was a problem running the Chef provisioner'
        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        write-Error $_
        return $false
    }
}

end {
    Write-Debug -Message 'Chef deprovisioner: ending'
}