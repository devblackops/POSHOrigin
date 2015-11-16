[cmdletbinding()]
param(
    [parameter(mandatory)]
    $Options
)

begin {
    Write-Debug -Message 'DomainJoin provisioner test: beginning'
}

process {
    Write-Verbose -Message 'Testing DomainJoin provisioner...'

    $provOptions = ConvertFrom-Json -InputObject $Options.Provisioners
    $djOptions = $provOptions | Where-Object {$_.name -eq 'DomainJoin'}

    $t = Get-VM -Id $Options.vm.Id -Verbose:$false -Debug:$false
    $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1
    if ($null -ne $ip -and $ip -ne [string]::Empty) {
        $cmd = {
            $compSys = Get-WmiObject -Class Win32_ComputerSystem
            if ($compSys.PartOfDomain) {
                if ($compSys.Domain -ne $args[0].domain) {
                    # Computer is joined to a different domain then the one defined in options
                    return $false
                } else {
                    # Computer is joined to the same domain as defined in options
                    return $true
                }
            } else {
                # Computer is not joined to a domain
                return $false
            }
        }

        if ($null -ne $Options.DomainJoinCredentials) {
            $params = @{
                ComputerName = $ip
                Credential = $Options.GuestCredentials
                ScriptBlock = $cmd
                ArgumentList = $djOptions.options
            }
            $result = Invoke-Command @params
            Write-Verbose -Message "DomainJoin test: $result"
            return $result
        } else {
            throw 'DomainJoin options were not found in provisioner options!'
        }
    }
}

end {
    Write-Debug -Message 'DomainJoin provisioner test: ending'
}