[cmdletbinding()]
param(
    [parameter(mandatory)]
    $Options
)

begin {
    Write-Debug -Message 'Chef provisioner test: beginning'
}

process {
    # Test to see if the Chef client is already installed
    $chefInstalled = $false
    try {
        $t = Get-VM -Id $options.vm.Id -Verbose:$false -Debug:$false
        $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1
        if ($null -ne $ip -and $ip -ne [string]::Empty) {
            $params = @{
                Query = 'SELECT Name FROM Win32_Service WHERE Name = "chef-client"'
                ComputerName = $ip
                Credential = $Options.GuestCredentials
            }
            $chefSvc = Get-WmiObject @params

            if ($chefSvc) {
                $chefInstalled = $true
            } else {
                Write-Verbose -Message 'Chef client not found'
                $chefInstalled = $false
            }
        } else {
            Write-Error -Message 'No valid IP address returned from VM view. Can not test for Chef client'
        }

        return $chefInstalled
        #$params = @{
        #    Query = 'SELECT Name FROM Win32_Service WHERE Name = "chef-client"'
        #    ComputerName = $Options.Name
        #    Credential = $Options.GuestCredentials
        #}
        #$chefSvc = Get-WmiObject @params
        #if ($chefSvc) {
        #    return $true
        #} else {
        #    Write-Verbose -Message 'Chef client not found'
        #    return $false
        #}
    } catch {
        Write-Error -Message 'There was a problem testing for the Chef client'
        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        write-Error $_
        return $false
    }
}

end {
    Write-Debug -Message 'Chef provisioner test: ending'
}