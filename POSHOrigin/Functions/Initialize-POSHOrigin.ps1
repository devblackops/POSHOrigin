function Initialize-POSHOrigin {
    <#
        .SYNOPSIS
            Initializes the POSHOrigin configuration repository, configures the LCM, and adjusts WSMan settings.
        .DESCRIPTION
            - Initializes the POSHOrigin configuration repository that will hold default values for cmdlet parameters.
            - Configures the DSC Local Configuration Manager on the local host for PUSH mode.
            - Sets WSMan TrustedHosts to '*' in order to allow PowerShell remoting to a machine by IP address.
        .PARAMETER Repository
            Path to folder that will store POSHOrigin configuration options. 
            
            Default value is $env:USERPROFILE\.poshorigin\
            
        .PARAMETER DscServer            
            Unused. Reserved for future implementation.
        
        .PARAMETER ProvisioningServer
            Computer name of provisioning server. DSC configurations will be applied to this machine and executed there. 
            
            Default is localhost
        
        .PARAMETER ProvisioningServerCertPath
            Unused. Reserved for future implementation.
            
        .PARAMETER SmtpServer
            Unused. Reserved for future implementation.
        
        .PARAMETER SmtpPort
            Unused. Reserved for future implementation.
                
        .PARAMETER ConfigsPath
            Path to folder that will hold the configuration snippets.
            
            Default value is $env:USERPROFILE\.poshorigin\configs      
            
        .EXAMPLE
            Initialize POSHOrigin with default values.
            
            Initialize-POSHOrigin -Verbose
            
        .EXAMPLE
            Initialize POSHOrigin by setting the repository path to c:\poshorigin\ and the configuration snippets path to c:\myconfigs\.       
            
            Initialize-POSHOrigin -Repository 'c:\poshorigin' -ConfigsPath 'c:\myconfigs' -Verbose
    #>
    [cmdletbinding(HelpUri='https://github.com/devblackops/POSHOrigin/wiki/Initialize-POSHOrigin')]
    param(
        [string]$Repository = (Join-Path -path $env:USERPROFILE -ChildPath '.poshorigin'),

        [string]$DscServer = '',
        
        [string]$ProvisioningServer = 'localhost',

        [string]$ProvisioningServerCertPath = '',

        [string]$SmtpServer = '',

        [int]$SmtpPort = 25,

        [string]$ConfigsPath
    )

    begin {
        Write-Debug -Message $msgs.init_begin
    }

    process {

        $optionsPath = (Join-Path -Path $Repository -ChildPath 'options.json')
        if ($ConfigsPath -eq [string]::Empty) {
            $ConfigsPath = (Join-Path -Path $Repository -ChildPath 'configs')
        }

        if (-not (Test-Path -Path $Repository -Verbose:$false)) {
            Write-Verbose -Message $msgs.init_create_repo -f $Repository

            New-Item -ItemType Directory -Path $Repository -Verbose:$false | Out-Null
            New-Item -ItemType Directory -Path (Join-Path -Path $Repository -ChildPath 'configs') | Out-Null
            New-Item -ItemType Directory -Path (Join-Path -Path $Repository -ChildPath 'configs\common') | Out-Null
          
            $options = @{
                configs_path = $ConfigsPath
                dsc_server = $DscServer
                provisioning_server = $ProvisioningServer
                provisioning_server_cert_path = $ProvisioningServerCertPath
                smtp_server = $SmtpServer
                smtp_port = $SmtpPort
            }
            $json = $options | ConvertTo-Json -Verbose:$false
            $json | Out-File -FilePath $optionsPath -Force -Confirm:$false -Verbose:$false

        } else {
            Write-Verbose -Message ($msgs.init_repo_already_exists -f $Repository)

            if (Test-Path -Path $optionsPath) {
                $currOptions = (Get-Content -Path $optionsPath -Raw) | ConvertFrom-Json

                if ($currOptions.configs_path -ne $ConfigsPath) {
                    $currOptions.configs_path = $ConfigsPath
                }
                if ($currOptions.dsc_server -ne $DscServer) {
                    $currOptions.dsc_server = $DscServer
                }
                if ($currOptions.provisioning_server -ne $ProvisioningServer) {
                    $currOptions.provisioning_server = $ProvisioningServer
                }
                if ($currOptions.provisioning_server_cert_path -ne $ProvisioningServerCertPath) {
                    $currOptions.provisioning_server_cert_path = $ProvisioningServerCertPath
                }
                if ($currOptions.smtp_server -ne $SmtpServer) {
                    $currOptions.smtp_server = $SmtpServer
                }
                if ($currOptions.smtp_port -ne $SmtpPort) {
                    $currOptions.smtp_port = $SmtpPort
                }
            } else {
                $options = @{
                    configs_path = $ConfigsPath
                    dsc_server = $DscServer
                    provisioning_server = $ProvisioningServer
                    provisioning_server_cert_path = $ProvisioningServerCertPath
                    smtp_server = $SmtpServer
                    smtp_port = $SmtpPort
                }
                $json = $options | ConvertTo-Json -Verbose:$false
                $json | Out-File -FilePath $optionsPath -Force -Confirm:$false -Verbose:$false       
            }
        }

        if (-Not (_IsSessionElevated)) {
            [string[]]$argList = @('-NoProfile', '-NoExit', '-File', "$moduleRoot\Internal\_SetupLCM.ps1")
            $argList += $MyInvocation.BoundParameters.GetEnumerator() | Foreach {"-$($_.Key)", "$($_.Value)"}
            $argList += $MyInvocation.UnboundArguments
            Start-Process PowerShell.exe -Verb Runas -WorkingDirectory $pwd -ArgumentList $argList 
            return
        } else {
            _SetupLCM
        }
    }

    end {
        Write-Debug -Message $msgs.init_end
    }
}