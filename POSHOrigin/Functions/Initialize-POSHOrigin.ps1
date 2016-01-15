function Initialize-POSHOrigin {
    [cmdletbinding()]
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
        Write-Debug -Message 'Initialize-POSHOrigin(): beginning'
    }

    process {

        $optionsPath = (Join-Path -Path $Repository -ChildPath 'options.json')
        if ($ConfigsPath -eq [string]::Empty) {
            $ConfigsPath = (Join-Path -Path $Repository -ChildPath 'configs')
        }

        if (-not (Test-Path -Path $Repository -Verbose:$false)) {
            Write-Verbose "Creating POSHOrigin configuration repository: $Repository"
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
            Write-Verbose "POSH origin configuration repository appears to already be created at [$Repository]"

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

        #$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

        if (-Not (_IsSessionElevated)) {
            [string[]]$argList = @('-NoProfile', '-NoExit', '-File', "$moduleRoot\Internal\_SetupLCM.ps1")
            $argList += $MyInvocation.BoundParameters.GetEnumerator() | Foreach {"-$($_.Key)", "$($_.Value)"}
            $argList += $MyInvocation.UnboundArguments
            Start-Process PowerShell.exe -Verb Runas -WorkingDirectory $pwd -ArgumentList $argList 
            return
        } else {
            _SetupLCM
        }

        #return Get-Item -Path $Repository
    }

    end {
        Write-Debug -Message 'Initialize-POSHOrigin(): ending'
    }
}