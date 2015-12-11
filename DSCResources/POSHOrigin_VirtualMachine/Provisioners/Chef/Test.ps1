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

    $provOptions = ConvertFrom-Json -InputObject $Options.Provisioners
    $chefOptions = ($provOptions | Where-Object {$_.name -eq 'chef'}).options

    $match = $false
    try {
        $t = Get-VM -Id $options.vm.Id -Verbose:$false -Debug:$false
        $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1
        if ($null -ne $ip -and $ip -ne [string]::Empty) {

            $cmd = {
                $VerbosePreference = $Using:VerbosePreference
                $chefOptions = $args[0]
                $chefSvc = Get-Service -Name chef-client -ErrorAction SilentlyContinue
                if ($chefSvc) {
                    Write-Verbose -Message 'Chef client found'
                    $match = $true

                    # Lets do additional tests to verify the run list, environment, and attributes
                    $json = knife node show $chefOptions.nodename -m -F json
                    $node = $json | ConvertFrom-Json

                    # Verify environment
                    if ($node.chef_environment.ToLower() -ne $chefOptions.environment.ToLower()) {
                        Write-Verbose -Message "Chef environment doesn't match [$($node.chef_environment.ToLower()) <> $($chefOptions.environment.ToLower()))"
                        $match = $false
                    }

                    # Verify run list matches
                    if (@($node.run_list).Count -ne @($chefOptions.runlist).Count) {
                        $currList = @($node.run_list) | Sort
                        $currList = @($node.run_list) | Sort
                        $configList = @($chefOptions.runlist) | ForEach-Object {
                            if ($_.recipe) {
                                "recipe[$($_.recipe)]"
                            } elseif ($_.role) {
                                "role[$($_.role)]"
                            }
                        }
                        if ($null -eq $configList) { $configList = @()}
                        $configList = $configList | sort

                        if (Compare-Object -ReferenceObject $configList -DifferenceObject $currList) {
                            Write-Verbose -Message "Chef run list does not match"
                            $match = $false
                        }
                    }

                    # Verify attributes
                    if ($chefOptions.attributes) {
                        if (Compare-Object -ReferenceObject $chefOptions.attributes -DifferenceObject $node.normal) {
                            Write-Verbose -Message "Chef attributes do not match"
                            $match = $false
                        }
                    }
                } else {
                    Write-Verbose -Message 'Chef client not found'
                    $match = $false
                }
                return $match
            }

            $params = @{
                ComputerName = $ip
                Credential = $Options.GuestCredentials
                ScriptBlock = $cmd
                ArgumentList = $chefOptions
            }
            $match = Invoke-Command @params
        } else {
            Write-Error -Message 'No valid IP address returned from VM view. Can not test for Chef client'
        }

        return $match
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