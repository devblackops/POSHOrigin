function Invoke-POSHOrigin {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string]$ProvisioningServer = (_GetOption -Option 'provisioning_server'),

        [string]$DscServer = (_GetOption -Option 'dsc_server'),

        #[pscredential]$Credential = (Get-Credential -Message 'Enter admin credentials for DSC server.'),
        
        [string]$Path = (_GetOption -Option 'configs_path'),

        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('InputObject')]
        [psobject[]]$ConfigData,

        [switch]$PassThru,
        
        [switch]$MakeItSo,

        [switch]$KeepMOF
    )

    begin {
        Write-Debug -Message $msgs.ipo_begin
        $data = @()
    }

    process {
        $ConfigData | foreach-object {
            $data += $_
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
        $mofPath = _CompileConfig -ConfigData $data -ProvisioningServer $ProvisioningServer -DscServer $DscServer -WhatIf:$false

        if (Test-Path -Path $mofPath) {
            Write-Verbose -Message ($msgs.ipo_mof_generated -f $mofPath.FullName)

            # Publish MOF to provisioning server if not local.
            # Otherwise, start DSC configuration locally
            if ($ProvisioningServer -ne 'localhost' -and $ProvisioningServer -ne '.' -and $ProvisioningServer -ne $env:COMPUTERNAME) {
                if ($PSCmdlet.ShouldProcess($msgs.ipo_should_msg)) {
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

    #Remove-DSCConfigurationDocument -Stage Current;
    #$cmd = {
    #    Remove-DSCConfigurationDocument -Stage Current;
    #    Update-DSCConfiguration -wait -verbose
    #}
    #Remove-DSCConfigurationDocument -Stage Current -CimSession $ProvisioningServer -Credential $Credential
    #Update-DSCConfiguration -CimSession $ProvisioningServer -wait -verbose -Credential $Credential
    #Invoke-Command -ComputerName $ProvisioningServer -Credential $Credential -ScriptBlock $cmd
}