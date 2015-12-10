[cmdletbinding()]
param(
    [parameter(mandatory)]
    $Options
)

begin {
    Write-Debug -Message 'DomainJoin deprovisioner: beginning'
}

process {
    Write-Verbose -Message 'Running DomainJoin deprovisioner...'
    $provOptions = ConvertFrom-Json -InputObject $Options.Provisioners
    $djOptions = $provOptions | Where-Object {$_.name -eq 'DomainJoin'}

    $t = Get-VM -Id $Options.vm.Id -Verbose:$false -Debug:$false
    $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1
    if ($null -ne $ip -and $ip -ne [string]::Empty) {
        $cmd = {
            try {
                $params = @{
                    UnJoinDomainCredential = $args[0]
                    WorkgroupName = 'WORKGROUP'
                    Force = $true
                }
                Write-Verbose -Message "Removing computer from domain [$($args[1])]"
                Remove-Computer @params | Out-Null
            } catch {
                Write-Error -Message 'There was a problem running the Chef provisioner'
                Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                write-Error $_
            }
        }

        if ($null -ne $Options.DomainJoinCredentials) {
            $params = @{
                ComputerName = $ip
                Credential = $Options.GuestCredentials
                ScriptBlock = $cmd
                ArgumentList = @(
                    $Options.DomainJoinCredentials,
                    $djOptions.options.domain
                )
            }
            Invoke-Command @params
        } else {
            throw 'DomainJoin options were not found in provisioner options!'
        }
    }
}

end {
    Write-Debug -Message 'DomainJoin deprovisioner: ending'
}