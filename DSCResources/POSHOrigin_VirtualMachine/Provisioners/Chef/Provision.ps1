[cmdletbinding()]
param(
    [parameter(mandatory)]
    $Options
)

begin {
    Write-Debug -Message 'Chef provisioner: beginning'
}

process {
    try {
        Write-Verbose -Message 'Configuring Chef client...'
        $provOptions = ConvertFrom-Json -InputObject $Options.Provisioners
        $chefOptions = $provOptions | Where-Object {$_.name -eq 'chef'}

        $t = Get-VM -Id $Options.vm.Id -Verbose:$false -Debug:$false
        $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1
        if ($null -ne $ip -and $ip -ne [string]::Empty) {
            $cmd = {
                $VerbosePreference = 'Continue'
                try {
                    $options = $args[0]
                    $provOptions = $args[1].options
                    $source = $provOptions.source
                    $sourceName = 'chef-client.msi'
                    $validatorKey = $provOptions.validatorKey
                    $validatorName = $validatorKey.split('/') | Select-Object -Last 1
                    $cert = $provOptions.cert
                    $certName = $cert.split('/') | Select-Object -Last 1
                    $runList = $provOptions.runList

                    # Ensure Chef node name is always lowercase
                    $fqdn = $provOptions.nodeName
                    $fqdnlower = $fqdn.ToLower()

                    $chefSvc = Get-Service -Name chef-client -ErrorAction SilentlyContinue
                    $chefGotInstalled = $false
                    if ($null -eq $chefSvc) {
                        Write-Verbose -Message 'Installing Chef client...'
                        # Copy Chef items locally
                        New-Item -Path "C:\Windows\Temp\ChefClient" -ItemType Directory -Force
                        Invoke-WebRequest -Uri $source -OutFile "c:\windows\temp\ChefClient\$sourceName"
                        Invoke-WebRequest -Uri $validatorKey -OutFile "c:\windows\temp\ChefClient\validator.pem"
                        Invoke-WebRequest -Uri $cert -OutFile "c:\windows\temp\ChefClient\$certName"

                        # Install Chef
                        $params = @{
                            FilePath = 'msiexec'
                            ArgumentList = '/qn /i c:\windows\temp\ChefClient\' + $sourceName + ' ADDLOCAL="ChefClientFeature,ChefServiceFeature"'
                            Wait = $true
                        }
                        Start-Process @params

                        # Add Chef to env vars
                        If ($env:Path -notmatch 'C:\\opscode\\chef\\bin' -and $env:Path -notmatch 'c:\\opscode\\chef\\embedded\\bin') {
                            [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\opscode\chef\bin;C:\opscode\chef\embedded\bin", [System.EnvironmentVariableTarget]::Machine)
                            $env:Path = $env:Path + ";C:\opscode\chef\bin;C:\opscode\chef\embedded\bin"
                        }

                        # This doesn't work
                        #$fqdn = $provOptions.nodeName.ToLower()

                        $url = $provOptions.url
                        $validatorClientName = $validatorName.split('.')[0]
                        $knifeRB= @"
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "$fqdnlower"
client_key               "c:\\chef\\client.pem"
validation_client_name   "$validatorClientName"
validation_key           "c:\\chef\\validator.pem"
chef_server_url          "$url"
cookbook_path            ["C:\\chef_cookbooks"]
"@

                        $clientRB = @"
chef_server_url         "$url"
validation_client_name  "$validatorClientName"
validation_key          "c:\\chef\\validator.pem"
client_key              "c:\\chef\\client.pem"
node_name               '$fqdnlower'
"@
                        New-Item -Path "$HOME\.chef" -ItemType Directory -ErrorAction SilentlyContinue -Force
                        $knifeRB | Out-File -FilePath "$HOME\.chef\knife.rb" -Encoding ascii -Force
                        $clientRB | Out-File -FilePath 'c:\chef\client.rb' -Encoding ascii -Force

                        # Copy certs
                        New-Item -Path "$HOME\.chef\trusted_certs" -ItemType Directory -ErrorAction SilentlyContinue
                        New-Item -Path 'c:\chef\trusted_certs' -Type Directory -Force -ErrorAction SilentlyContinue
                        Copy-Item -Path "c:\windows\temp\ChefClient\$certName" -Destination 'c:\chef\trusted_certs' -Force
                        Copy-Item -Path "c:\windows\temp\ChefClient\$certName" -Destination "$HOME\.chef\trusted_certs" -Force
                        Copy-Item -Path "c:\windows\temp\ChefClient\validator.pem" -Destination 'c:\chef' -Force

                        # Start Chef as service
                        Start-Process -FilePath 'chef-service-manager' -ArgumentList '-a install' -NoNewWindow -Wait
                        Start-Process -FilePath 'chef-service-manager' -ArgumentList '-a start' -NoNewWindow -Wait
                        Start-Process -FilePath 'chef-client' -NoNewWindow -Wait
                        
                        # Cleanup
                        #Remove-Item -Path "c:\chef\validator.pem" -Force
                        #Remove-Item -Path "c:\chef\$clientName"
                        Remove-Item -Path 'c:\windows\temp\chefclient\' -Recurse -Force

                        $chefGotInstalled = $true
                    }

                    # Add Chef to env vars
                    If ($env:Path -notmatch 'C:\\opscode\\chef\\bin' -and $env:Path -notmatch 'c:\\opscode\\chef\\embedded\\bin') {
                        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\opscode\chef\bin;C:\opscode\chef\embedded\bin", [System.EnvironmentVariableTarget]::Machine)
                        $env:Path = $env:Path + ";C:\opscode\chef\bin;C:\opscode\chef\embedded\bin"
                    }

                    # Sleep a little if we just installed Chef
                    if ($chefGotInstalled) {
                        Write-Verbose -Message 'Chef installed. Sleeping...'
                        Start-Sleep -Seconds 5
                    }

                    # Lets do additional tests to verify the run list, environment, and attributes
                    Write-Verbose -Message 'Getting Chef node...'
                    $json = knife node show $provOptions.nodename -m -F json
                    $node = $json | ConvertFrom-Json

                    # Verify run list matches
                    if ($provOptions.runlist) {
                        if (@($node.run_list).Count -ne @($provOptions.runlist).Count) {
                            # Current run list
                            $currList = @($node.run_list) | Sort
                            if ($null -eq $currList) { $currList = @()}

                            # Desired run list
                            $configList = @($provOptions.runlist) | ForEach-Object {
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
                            
                                # Set run list
                                $list = ''
                                $runlist | ForEach-Object {
                                    $propName = $_ | Get-Member -Type NoteProperty
                                    $value = $_."$($propName.Name)"
                                    $list += "$($propName.Name)[$value],"
                                }
                                $list = $list.TrimEnd(',')
                                $list = "'$list'"
                                Write-Verbose -Message "Assigning run list: $fqdnlower $($list | Format-List | Out-String)"
                                Start-Process -FilePath 'knife' -ArgumentList "node run_list set $fqdnlower $list" -NoNewWindow -Wait
                            }
                        }
                    }

                     # Verify environment
                    if ($provOptions.environment) {
                        if ($node.chef_environment.ToLower() -ne $provOptions.environment.ToLower()) {
                            Write-Verbose -Message "Assigning Chef environment: $($provOptions.environment)"
                            Start-Process -FilePath 'knife' -ArgumentList "node environment set $fqdnlower $($provOptions.environment.ToLower())" -NoNewWindow -Wait
                        }
                    }

                    # Assign attributes if needed
                    if ($provOptions.attributes) {
                        $attribCmds = @()
                        $provOptions.attributes | Get-Member -Type NoteProperty | Foreach-Object {
                            $attrName = $_.Name
                            $attrValue = $provOptions.attributes."$($attrName)"
                            
                            # Construct our cmd to set the attribute with the JSON data
                            $cmd = 'exec -E "nodes.find(:name => ''' + $fqdnlower + "')"
                            $cmd += " {|n| n.normal_attrs.$attrName = "

                            if ($attrValue -is [string]) {
                                $cmd += "'" + $attrValue + "'"
                            } else {
                                $cmd += $attrValue
                            }
                            $cmd += '; n.save; }"'
                            $attribCmds += $cmd
                        }
                        if ($attribCmds.Count -gt 0) {
                            Write-Verbose -Message "Assigning Chef attributes: $($provOptions.attributes | Format-List -Property * | Out-String)"
                            $attribCmds | ForEach-Object {
                                Write-Verbose -Message "knife $_"
                                Start-Process -FilePath 'knife' -ArgumentList $_ -NoNewWindow -Wait
                            }
                        }
                    }
                } catch {
                    Write-Error -Message 'There was a problem running the Chef provisioner'
                    Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                    write-Error $_
                }
            }

            $params = @{
                ComputerName = $ip
                Credential = $Options.GuestCredentials
                ScriptBlock = $cmd
                ArgumentList = @($Options, $chefOptions)
            }
            Invoke-Command @params
        } else {
           Write-Error -Message 'No valid IP address returned from VM view. Can not configure the Chef client'
        }
    } catch {
        Write-Error -Message 'There was a problem running the Chef provisioner'
        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        write-Error $_
        return $false
    }
}

end {
    Write-Debug -Message 'Chef provisioner: ending'
}