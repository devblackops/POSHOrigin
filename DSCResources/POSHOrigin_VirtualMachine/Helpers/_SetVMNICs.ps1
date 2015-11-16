function _SetVMNICs {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$NICSpec,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CustomizationSpec,

        [string]$IPAMFqdn,

        [pscredential]$IPAMCredentials
    )

    $success = $false
    $specClone = $null
                    
    $netConfigs = @(ConvertFrom-Json -InputObject $NICSpec)
    Write-Debug "Configuration NIC count: $($netConfigs.count)"

    $vmNICs = @($vm | Get-NetworkAdapter -Verbose:$false -Debug:$false)
    Write-Debug "VM NIC count: $($vmNICs.Count)"

    # Assign each vNIC to the appropriate port group
    $num = 1
    foreach ($netConfig in $netConfigs) {
        $vmNIC = $vmNICs[$num-1]
        try {
            if ($vmNIC -ne $null) {

                Write-Debug "Setting NIC $num to port group [$($netConfig.PortGroup)]"
                
                $x = Set-NetworkAdapter -NetworkAdapter $vmnic -NetworkName $netConfig.PortGroup -Verbose:$false -Confirm:$false
                $x = $x | Set-NetworkAdapter -StartConnected:$true -Verbose:$false -Confirm:$false
                <#
                $t = Set-NetworkAdapter -NetworkAdapter $vmnic -NetworkName $netConfig.PortGroup -RunAsync -Verbose:$false -Confirm:$false
                # Wait for task to complete
                while ($t.State.ToString().ToLower() -eq 'running') {
                    Start-Sleep -Seconds 5
                    $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
                }
                $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
                if ($t.State.ToString().ToLower() -eq 'success') {
                    $x = Get-NetworkAdapter -Id $vmnic.Id -Verbose:$false -Debug:$false

                    $t = $x | Set-NetworkAdapter -StartConnected:$true -RunAsync -Verbose:$false -Confirm:$false
                    # Wait for task to complete
                    while ($t.State.ToString().ToLower() -eq 'running') {
                        Start-Sleep -Seconds 5
                        $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
                    }
                }
                #>
            } else {
                Write-Debug "Adding new NIC for port group [$($netConfig.PortGroup)]"              
                $x = New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $netConfig.PortGroup -Verbose:$false -Confirm:$false
                $x = $x | Set-NetworkAdapter -StartConnected:$true -Verbose:$false -Confirm:$false

                <#
                $x = New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $netConfig.PortGroup -Verbose:$false -Confirm:$false
                $t = $x | Set-NetworkAdapter -StartConnected:$true -RunAsync -Verbose:$false -Confirm:$false
                # Wait for task to complete
                while ($t.State.ToString().ToLower() -eq 'running') {
                    Start-Sleep -Seconds 5
                    $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
                }
                #>
            }
        } catch {
            Write-error 'There was a problem setting or creating the NIC'
            Write-error "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            Write-error $_
        }
        $num += 1
    }
    $vm = Get-VM $vm -Verbose:$false -Debug:$false

    # Create a non-persistent clone of the customization spec
    $spec = Get-OSCustomizationSpec -Name $CustomizationSpec -Type Persistent -Verbose:$false | Select-Object -First 1
    Write-Debug -Message "Customization spec: $($spec.Name)"
    if ($spec -ne $null) {       

        # Remove any non-persistant clones that may have been left behind
        Write-Debug -Message 'Removing any orphaned specs'
        $oldSpecs = Get-OSCustomizationSpec -Type NonPersistent -Name $spec.Name -Verbose:$false -ErrorAction SilentlyContinue
        if ($oldSpecs) {
            $oldSpecs | Remove-OSCustomizationSpec -Confirm:$false
        }

        Write-Debug -Message 'Cloning customization spec'
        $specClone = New-OSCustomizationSpec -Spec $spec -Type NonPersistent -Verbose:$false
    } else {
        Write-Warning -Message "Customization spec [$($CustomizationSpec)] not found."
    }

    if ($null -ne $specClone) {

        # Remove any NIC mappings from the spec
        $nicMapping = Get-OSCustomizationNicMapping -OSCustomizationSpec $specClone -Verbose:$false
        Remove-OSCustomizationNicMapping -OSCustomizationNicMapping $nicMapping -Verbose:$false -Confirm:$false
        $nicMapping = Get-OSCustomizationNicMapping -OSCustomizationSpec $specClone -Verbose:$false 
        
        $vmNICs = @($vm | Get-NetworkAdapter -Verbose:$false)
        
        $num = 1                                                                                                                                                                                                                                                                                                                                                            
        foreach ($netConfig in $netConfigs) {
            Write-Debug -Message ($netConfig | Format-List -Property * | Out-String)
            Write-Verbose -Message "Configuring NIC $num"
            $vmNIC = $vmNICs[$num-1]

            # Set NIC customizations                               
            switch ($netConfig.IPAssignment) {
                'Static' {
                    # Create a NIC mapping
                    try {
                        Write-Verbose -Message "Setting static IP [$($netConfig.IPAddress)] for NIC $num"

                        $params = @{
                            OSCustomizationSpec = $specClone
                            IpMode = 'UseStaticIp'
                            IpAddress = $netConfig.IPAddress
                            SubnetMask = $netConfig.SubnetMask
                            DefaultGateway = $netConfig.DefaultGateway
                            Dns = $netConfig.DNSServers
                            Verbose = $false
                        }
                        if ($vmNIC -ne $null) {
                            $params.NetworkAdapterMac = $vmNic.MacAddress                            
                        }
                        New-OSCustomizationNicMapping @params
                        $success = $true
                    } catch {
                        Write-Error -Message 'There was a problem setting the NIC to static'
                        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                        Write-error $_
                    }                        
                }
                'DHCP' {
                    try {
                        Write-Verbose -Message "Setting DHCP for NIC $num"
                        if ($vmNIC -ne $null) {
                            New-OSCustomizationNicMapping -OSCustomizationSpec $specClone -IpMode UseDhcp -Verbose:$false
                        } else {
                            New-OSCustomizationNicMapping -OSCustomizationSpec $specClone -IpMode UseDhcp -NetworkAdapterMac $vmNIC.MacAddress -Verbose:$false
                        }                            
                        #Set-VM -VM $vm -OSCustomizationSpec $specClone -Confirm:$false
                        #Remove-OSCustomizationSpec -OSCustomizationSpec $specClone -Confirm:$false
                        $success = $true
                    } catch {
                        Write-Error -Message 'There was a problem setting the NIC to DHCP'
                        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                        Write-error $_
                    }
                }
                'IPAMNextAvailable' {
                    try {
                        $IPInfo = _RequestInfoBloxIP -Name $VM.Name -Network $netConfig.Network -GridServer $IPAMFqdn -Credential $IPAMCredentials

                        # Create NIC mapping with IP info
                        if ($null -ne $IPInfo) {
                            Write-Verbose -Message "Setting IPAM assigned static IP [$($IPInfo.ipv4addr)] for NIC $num"

                            $params = @{
                                OSCustomizationSpec = $specClone
                                IpMode = 'UseStaticIp'
                                IpAddress = $IPInfo.ipv4addr 
                                SubnetMask = $IPInfo.subnetMask
                                DefaultGateway = $IPInfo.gateway 
                                Dns = $netConfig.DNSServers
                            }
                            Write-Verbose -Message ($params | fl * | out-string)

                            if ($vmNIC -ne $null) {
                                $params.NetworkAdapterMac = $vmNIC.MacAddress
                            }
                            New-OSCustomizationNicMapping @params -Verbose:$false
                            $success = $true
                        } else {
                            Write-Error -Message 'Failed to resolve required network information IPAM'
                        }
                    } catch {
                        $success = $false
                        Write-Error -Message 'There was a problem setting the NIC mapping'
                        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                        Write-error $_
                    }
                }
                Default {
                    try {
                        Write-Warning -Message "No valid network configuration found in config. Defaulting to DHCP."
                        Write-Verbose -Message "Setting DHCP for NIC $num"
                        $nicMapping | New-OSCustomizationNicMapping -IpMode UseDhcp -Verbose:$false
                        $success = $true                          
                    } catch {
                        $success = $false
                        Write-Error -Message 'There was a problem setting the NIC mapping'
                        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                        Write-error $_
                    }
                }
            }                
            $num += 1
        }
            
        # Apply the NIC customizations
        if ($null -ne $specClone) {
            Write-Debug -Message 'Applying VM customization spec...'
          
            try {
                # Verify the IP address(s) that we're about to set are not already in use
                $ips = Get-OSCustomizationNicMapping -OSCustomizationSpec $specClone -Verbose:$false
                foreach ($mapping in $ips) {
                    $pingable = Test-Connection -ComputerName $mapping.IPAddress -Count 1 -Quiet
                    if ($pingable) {
                        throw "$($mapping.IPAddress) appears to already be in use. Failed to set this IP."
                    }
                }
                
                # Refresh our VM object as we may have added / modified NICs
                $vm = Get-VM $vm -Verbose:$false -Debug:$false

                Set-VM -VM $vm -OSCustomizationSpec $specClone -Verbose:$false -Confirm:$false
                #$t = Set-VM -VM $vm -OSCustomizationSpec $specClone -RunAsync -Verbose:$false -Confirm:$false
                #while ($t.State.ToString().ToLower() -eq 'running') {
                   #Start-Sleep -Seconds 5
                    #$t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
                #}
                #$t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
                #if ($t.State.ToString().ToLower() -eq 'success') {
                    #Remove-OSCustomizationSpec -OSCustomizationSpec $specClone -Verbose:$false -Confirm:$false
                #} else {
                    #Remove-OSCustomizationSpec -OSCustomizationSpec $specClone -Verbose:$false -Confirm:$false
                    #throw 'Failed to set OS customization spec'
                #}
            } catch {
                Write-Error -Message 'Failed to set OS customization spec'
                Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                Write-error $_
            }
        }
    } else {
        Write-Error -Message 'Unable to configue NICs without a valid customization spec'
        $success = $false
    }

    return $success
}