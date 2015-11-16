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
        Write-Verbose -Message 'Installing Chef client...'
        $provOptions = ConvertFrom-Json -InputObject $Options.Provisioners
        $chefOptions = $provOptions | Where-Object {$_.name -eq 'chef'}

        $t = Get-VM -Id $Options.vm.Id -Verbose:$false -Debug:$false
        $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1
        if ($null -ne $ip -and $ip -ne [string]::Empty) {
            $cmd = {
                try {
                    $options = $args[0]
                    $provOptions = $args[1].options
                    $source = $provOptions.source
                    $sourceName = $source.split('/') | Select-Object -Last 1
                    $clientKey = $provOptions.clientKey
                    $clientName = $clientKey.split('/') | Select-Object -Last 1
                    $validatorKey = $provOptions.validatorKey
                    $validatorName = $validatorKey.split('/') | Select-Object -Last 1
                    $cert = $provOptions.cert
                    $certName = $cert.split('/') | Select-Object -Last 1
                    $runList = $provOptions.runList

                    # Copy Chef items locally
                    New-Item -Path "C:\Windows\Temp\ChefClient" -ItemType Directory -Force
                    Invoke-WebRequest -Uri $source -OutFile "c:\windows\temp\ChefClient\$sourceName"
                    #Invoke-WebRequest -Uri $clientKey -OutFile "c:\windows\temp\ChefClient\$clientName"
                    Invoke-WebRequest -Uri $validatorKey -OutFile "c:\windows\temp\ChefClient\$validatorName"
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

                    #Create knife/client .rb files
                    #$fqdn = $env:COMPUTERNAME.ToUpper() + '.' + $env:USERDNSDOMAIN.ToLower()
                    $fqdn = $provOptions.nodeName

                    # Ensure Chef node name is always lowercase
                    
                    # This doesn't work
                    #$fqdn = $provOptions.nodeName.ToLower()

                    $url = $provOptions.url
                    $validatorClientName = $validatorName.split('.')[0]
                    $knifeRB= @"
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "$fqdn"
client_key               "c:\\chef\\client.pem"
validation_client_name   "$validatorClientName"
validation_key           "c:\\chef\\$validatorName"
chef_server_url          "$url"
cookbook_path            ["C:\\chef_cookbooks"]
"@

                        $clientRB = @"
chef_server_url         "$url"
validation_client_name  "$validatorClientName"
validation_key          "c:\\chef\\$validatorName"
"@
                    New-Item -Path "$HOME\.chef" -ItemType Directory -ErrorAction SilentlyContinue
                    $knifeRB | Out-File -FilePath "$HOME\.chef\knife.rb" -Encoding ascii
                    $clientRB | Out-File -FilePath 'c:\chef\client.rb' -Encoding ascii

                    # Copy certs
                    New-Item -Path "$HOME\.chef\trusted_certs" -ItemType Directory -ErrorAction SilentlyContinue
                    New-Item -Path 'c:\chef\trusted_certs' -Type Directory -Force -ErrorAction SilentlyContinue
                    Copy-Item -Path "c:\windows\temp\ChefClient\$certName" -Destination 'c:\chef\trusted_certs' -Force
                    Copy-Item -Path "c:\windows\temp\ChefClient\$certName" -Destination "$HOME\.chef\trusted_certs" -Force
                    Copy-Item -Path "c:\windows\temp\ChefClient\$validatorName" -Destination 'c:\chef' -Force
                    #Copy-Item -Path "c:\windows\temp\ChefClient\$clientName" -Destination 'c:\chef' -Force

                    Start-Process -FilePath 'chef-client' -Wait

                    # Start Chef as service
                    Start-Process -FilePath 'chef-service-manager' -ArgumentList '-a install' -NoNewWindow -Wait
                    Start-Process -FilePath 'chef-service-manager' -ArgumentList '-a start' -NoNewWindow -Wait

                    # Add run list
                    $list = ''
                    $runlist | ForEach-Object {
                        $propName = $_ | Get-Member -Type NoteProperty
                        $value = $_."$($propName.Name)"
                        $list += "$($propName.Name)[$value],"
                    }
                    $list = $list.TrimEnd(',')
                    $list = "'$list'"
                    Write-Verbose -Message "node run_list add $fqdn $list"
                    Start-Process -FilePath 'knife' -ArgumentList "node run_list add $fqdn $list" -NoNewWindow -Wait

                    # Cleanup
                    Remove-Item -Path "c:\chef\$validatorName" -Force
                    #Remove-Item -Path "c:\chef\$clientName"
                    Remove-Item -Path 'c:\windows\temp\chefclient\' -Recurse -Force
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