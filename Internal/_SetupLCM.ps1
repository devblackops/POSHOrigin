function _SetupLCM {
    [cmdletbinding()]
    param()

    #[DSCLocalConfigurationManager()]
    Configuration LCMPush {
        param(
            [string]$Computer = 'localhost'
        )

	    Node $Computer {
            LocalConfigurationManager {
                RefreshMode = 'Push'
                ConfigurationMode = 'ApplyAndAutoCorrect'
                AllowModuleOverwrite = $true
                ConfigurationModeFrequencyMins = 30
                RefreshFrequencyMins = 30
                RebootNodeIfNeeded = $false
            }
	    }
    }

    $tempDir = (Join-Path -Path $env:SystemDrive -ChildPath "Temp")
    if (!(Test-Path -Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory | out-null
    }

    # Create the Computer.Meta.Mof in folder
    Write-Verbose -Message 'Configuring DSC LCM...'
    $dir = LCMPush -computer 'localhost' -OutputPath $tempDir -Verbose:$false
    Set-DSCLocalConfigurationManager -Path $dir.Directory -Verbose:$false
    Remove-Item -Path $dir -Force

    # Enable PS remoting
    Write-Verbose -Message 'Configuration WSMAN...'
    Set-WSManQuickConfig -Force | Out-Null

    # Configure trusted hosts
    # This will allow PS remoting to IP address rather than name
    # We can't be sure that DNS resolution is working right after the VM is built
    # so we connect with IP address.
    Write-Verbose -Message 'Setting WSMan:\localhost\Client\TrustedHosts to [*]'
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value * -Force
}
