[cmdletbinding()]
param(
    [parameter(mandatory)]
    $Options
)

begin {
    Write-Debug -Message 'DomainJoin provisioner: beginning'
}

process {
    Write-Verbose -Message 'Running DomainJoin provisioner...'
    $provOptions = ConvertFrom-Json -InputObject $Options.Provisioners
    $djOptions = $provOptions | Where-Object {$_.name -eq 'DomainJoin'}

    $t = Get-VM -Id $Options.vm.Id -Verbose:$false -Debug:$false
    $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1
    if ($null -ne $ip -and $ip -ne [string]::Empty) {
        $cmd = {
            $VerbosePreference = 'Continue'
            try {
                $params = @{
                    Credential = $args[0]
                    DomainName = $args[1]
                    Force = $true
                    Restart = $true
                }
                if ($null -ne $args[2]) { $params.OUPath = $args[2] }
                $str = $params | ConvertTo-Json
                Write-Debug -Message "DomainJoin options:`n$str"
                Write-Verbose -Message "Joining domain [$($args[1])]"
                Add-Computer @params | Out-Null
                return $true
            } catch {
                Write-Error -Message 'There was a problem running the DomainJoin provisioner'
                Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                write-Error $_
                return $false
            }
        }

        if ($null -ne $Options.DomainJoinCredentials) {
            $params = @{
                ComputerName = $ip
                Credential = $Options.GuestCredentials
                ScriptBlock = $cmd
                ArgumentList = @(
                    $Options.DomainJoinCredentials,
                    $djOptions.options.domain,
                    $djOptions.options.OUPath
                )
            }
            $result = Invoke-Command @params

            if ($result) {
                # Wait for machine to reboot
                Write-Verbose -Message "Waiting for machine to become available..."
                Start-Sleep -Seconds 10
                $timeout = 5
                $sw = [diagnostics.stopwatch]::StartNew()
                while ($sw.elapsed.minutes -lt $timeout){
                    $vmView = $Options.vm | Get-View -Verbose:$false
                    if ($vmView.Guest.IpAddress -and $vmView.Guest.IpAddress -notlike '169.*') {
                        $p = Invoke-Command -ComputerName $vmView.Guest.IpAddress -Credential $Options.GuestCredentials -ScriptBlock { Get-Process } -ErrorAction SilentlyContinue
                        if ($null -ne $p) {

                            Write-Verbose -Message 'Running gpupdate /force...'
                            Invoke-Command -ComputerName $vmView.Guest.IpAddress -Credential $Options.GuestCredentials -ScriptBlock { gpupdate /force } -ErrorAction SilentlyContinue

                            break
                        }
                    }
                    Start-Sleep -Seconds 5
                    Write-Verbose -Message "Waiting for machine to become available..."
                }
            }
        } else {
            throw 'DomainJoin options were not found in provisioner options!'
        }
    }
}

end {
    Write-Debug -Message 'DomainJoin provisioner: ending'
}