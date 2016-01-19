function _CompileConfig {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string]$ProvisioningServer = (_GetOption -Option 'provisioning_server'),

        [string]$DscServer = (_GetOption -Option 'dsc_server'),

        [Parameter(Mandatory)]
        $ConfigData

        #$Certificate = "$(Join-Path -path $env:USERPROFILE -ChildPath '.poshorigin')\$($ProvisioningServer.Split('.')[0]).cer"

        #[string]$ProvisioningServerGuid = 'e7f0b61a-b833-466d-afc8-daf043ab8b9f'
    )

    begin {
        Write-Debug -Message $msgs.cc_begin
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

        # Validate we have a valid 'Ensure' settings
        foreach ($item in $ConfigData) {
            if (-not $item.options.Ensure) {
                $item.options | Add-Member -Type NoteProperty -Name Ensure -Value Present
            } else {
                if (($item.Options.Ensure -ne 'Present') -and ($item.Options.Ensure -ne 'absent')) {
                    $item.Options.Ensure -eq 'Present'
                }
            }
        }

        # Dot source any needed configurations based on the configData
        $ConfigData | ForEach-Object {

            # Derive the resource type and module from the options passed in
            # and try to find the DSC resource
            $module = $_.Resource.Split(':')[0]
            $resource = $_.Resource.Split(':')[1]
            $dscResource = Get-DscResource -Name $resource -Module $module -Verbose:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (-Not $dscResource) {
                $dscResource = Get-DscResource -Name $resource -Module "POSHOrigin_$module" -Verbose:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }
            if (-Not $dscResource) {
                $dscResource = Get-DscResource -Name $resource -Module 'POSHOrigin' -Verbose:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            # Dot source the configuration
            if ($dscResource) {
                $invokePath = Join-Path -Path $dscResource.ParentPath -ChildPath 'Invoke.ps1'
                Write-Verbose -Message ( $msgs.cc_generating_config -f $_.Resource, $_.Name)
                #Write-Verbose -Message ($msgs.cc_dot_sourcing_config -f $dscResource.Name, $invokePath)
                . $invokePath -Options $_ -Direct:$false
            }
        }

        Configuration POSHOrigin {
            Import-DscResource -ModuleName PSDesiredStateConfiguration

            Node $AllNodes.NodeName {
                $Node.Config | ForEach {
                       
                    Write-Debug -Message ($_.Options | Format-List -Property * | Out-String)

                    # Call the appropriate resource configuration
                    $resourceName = $_.Resource.Split(':')[1]
                    $configName = $_.Name.Replace('-', '_')
                    $confName = "$resourceName" + '_' + $configName
                    . $confName -ResourceOptions $_
                }
            }
        }

        # Create MOF file
        $repo = (Join-Path -path $env:USERPROFILE -ChildPath '.poshorigin')
        $source = POSHOrigin -ConfigurationData $DSCConfigData -OutputPath $repo -Verbose:$VerbosePreference

        return $source
    }

    end {
        Write-Debug -Message $msgs.cc_end
    }
}
