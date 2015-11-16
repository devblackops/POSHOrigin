function _CompileConfig {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        #[Parameter(Mandatory)]
        [string]$ProvisioningServer = (_GetOption -Option 'provisioning_server'),

        #[Parameter(Mandatory)]
        [string]$DscServer = (_GetOption -Option 'dsc_server'),

        [Parameter(Mandatory)]
        $ConfigData

        #$Certificate = "$(Join-Path -path $env:USERPROFILE -ChildPath '.poshorigin')\$($ProvisioningServer.Split('.')[0]).cer"

        #[string]$ProvisioningServerGuid = 'e7f0b61a-b833-466d-afc8-daf043ab8b9f'
    )

    begin {
        Write-Debug -Message '_CompileConfig(): beginning'
    }

    process {  
        $DSCConfigData = @{
            AllNodes = @(
                @{     
                    NodeName = "*"
                    #CertificateFile = "$repo\$($ProvisioningServer.Split('.')[0]).cer"
                    #Thumbprint = '6B63F5A78E990B04F2240874476CF45C8FBB19CA'
                    PSDscAllowPlainTextPassword = $true 
                    PSDscAllowDomainUser = $true
                }
                @{
                    NodeName = $ProvisioningServer
                    Config = $ConfigData
                }
            )
        }

        Configuration POSHOriginCompile {

            Import-DscResource -ModuleName POSHOrigin
            Import-DscResource -ModuleName POSHOrigin_NetScaler

            #$x = { Import-DscResource -ModuleName POSHOrigin
            #    Import-DscResource -ModuleName POSHOrigin_NetScaler
            #}
            #Invoke-Command $x

            #foreach ($item in $DSCConfigData.AllNodes[1].Config) {
            #    $mod = $_.Driver.Split(':')[0]
            #    $loadMod = "POSHOrigin_$mod" + "_Load"
            #    $resourceFile = "$moduleRoot\Internal\resources\$loadMod.ps1"
            #    #Write-Verbose $resourceFile
            #    #& $resourceFile
            #    . $resourceFile
            #    $c = "Import-DscResource -ModuleName $mod"
            #    & $c
            #}

            Write-Verbose -Message "`n`nStarting DSC MOF compilation..."
            Write-Debug -Message ($Node.Config | Format-List -Property '*' | Out-String)

            Node $AllNodes.NodeName {
                $Node.Config | ForEach {
                    # Validate we have a valid 'Ensure' settings
                    if ($null -eq $_.options.Ensure) {
                        $_.options | Add-Member -Type NoteProperty -Name 'Ensure' -Value 'Present'
                    } else {
                        if (($_.Options.Ensure -ne 'Present') -and ($_.Options.Ensure -ne 'absent')) {
                            $_.Options.Ensure -eq 'Present'
                        }
                    }

                    Write-Verbose "Generating config for: $($_.driver)($($_.Name))"
                    Write-Debug -Message ($_ | Select-Object -ExpandProperty options | Format-List -Property * | Out-String)

                    $module = $_.Driver.Split(':')[0]
                    $resource = $_.Driver.Split(':')[1]
                    _InvokeResource -Type ($module + "_" + $resource) -Options $_
                    #_InvokeResource -Type $x.Driver -Options $_
                }
            }
        }

        # This is our GUID for the provisioning server
        #$guid = [guid]::Parse($ProvisioningServerGuid)

        # Create MOF file
        $repo = (Join-Path -path $env:USERPROFILE -ChildPath '.poshorigin')
        $source = POSHOriginCompile -ConfigurationData $DSCConfigData -OutputPath $repo -Verbose:$false

        return $source
    }

    end {
        Write-Debug -Message '_CompileConfig(): ending'
    }
    
    # Publish MOF file
    #$target = "\\$DSCServer\C$\Program Files\WindowsPowerShell\DscService\Configuration\$Guid.mof"
    #Write-Verbose "Publishing MOF to [$target]"
    #Copy-Item -Path $source -Destination $target -Force -Verbose:$false
    #Remove-Item -Path $source -Force -Verbose:$false
    #New-DSCCheckSum $target -Force -Verbose:$false
}