function Invoke-POSHOrigin {
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName='Path')]
    param(
        [parameter(ParameterSetName='Path')]
        [parameter(ParameterSetName='InputObject')]
        [string]$ProvisioningServer = (_GetOption -Option 'provisioning_server'),
        
        [parameter(mandatory, position=0, ValueFromPipeline, ParameterSetName='Path')]
        [string]$Path,
        
        [Parameter(mandatory, position=0, ValueFromPipeline, ParameterSetName='InputObject')]
        [psobject[]]$InputObject,
        
        [parameter(ParameterSetName='Path')]
        [parameter(ParameterSetName='InputObject')]
        [switch]$PassThru,
        
        [parameter(ParameterSetName='Path')]
        [parameter(ParameterSetName='InputObject')]
        [switch]$MakeItSo,

        [parameter(ParameterSetName='Path')]
        [parameter(ParameterSetName='InputObject')]
        [switch]$KeepMOF
    )

    begin {
        Write-Debug -Message $msgs.ipo_begin
        $data = @()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $data = Get-POSHOriginConfig -Path $Path
        } else {
            $InputObject | foreach-object {
             $data += $_
            }    
        }
    }

    end {
        # Temporarilly disable the PowerShell progress bar
        $oldProgPref = $global:ProgressPreference
        $global:ProgressPreference = 'SilentlyContinue'

        $testResults = $null

        if ($PSBoundParameters.ContainsKey('MakeItSo')) {
            Write-Verbose -Message $msgs.ipo_makeitso
            $picard = Get-Content -Path "$moduleRoot\picard.txt" -Raw
            Write-Verbose -Message "`n$picard"
        }

        # Create MOF
        $mofPath = _CompileConfig -ConfigData $data -ProvisioningServer $ProvisioningServer -WhatIf:$false

        if (Test-Path -Path $mofPath) {
            Write-Verbose -Message ($msgs.ipo_mof_generated -f $mofPath.FullName)

            # Publish MOF to provisioning server if not local.
            # Otherwise, start DSC configuration locally
            $executeRemote = ($ProvisioningServer -ne 'localhost' -and $ProvisioningServer -ne '.' -and $ProvisioningServer -ne $env:COMPUTERNAME)
            if ($executeRemote) {
                if ($PSCmdlet.ShouldProcess($msgs.ipo_should_msg)) {
                    
                    # At some point we may want to support a pool of provisioning servers and come up with
                    # logic to pick an available one and publish/start the configuration on a provisiong server
                    # not currently executing a configuration                    
                    Publish-DscConfiguration -Path (Split-Path -Path $mofPath -Parent) -ComputerName $ProvisioningServer -Confirm:$false
                    Start-DscConfiguration -ComputerName $ProvisioningServer -Confirm:$false -Force -Wait
                }
            } else {
                if ($PSCmdlet.ShouldProcess($msgs.ipo_should_msg)) {
                    $testResults = Start-DscConfiguration -Path (Split-Path -Path $mofPath -Parent) -Force -Wait
                } else {
                    $testResults = Test-DscConfiguration -Path (Split-Path -Path $mofPath -Parent)
                }
            }

            # Cleanup
            if (-Not $PSBoundParameters.ContainsKey('KeepMOF')) {
                Remove-Item -Path $mofPath -Force -Confirm:$false -WhatIf:$false
            }
            Remove-DscConfigurationDocument -Stage Current, Pending -Force -Confirm:$false

            # Reset the progress bar preference
            $global:ProgressPreference = $oldProgPref

            Write-Debug -Message $msgs.ipo_end
        } else {
            Write-Error -Message $msgs.ipo_mof_failure
        }

        if ($PSBoundParameters.ContainsKey('PassThru')) {
            return $testResults
        }
    }
}