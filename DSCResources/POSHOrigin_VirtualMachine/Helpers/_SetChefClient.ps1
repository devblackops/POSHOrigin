function _SetChefClient{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OriginBootstrapSource,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ChefClient,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ChefRunList,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    begin {
        Write-Debug -Message 'Starting _SetChefClient()'
    }

    process {
        try { 
            $t = Get-VM -Id $vm.Id -Verbose:$false -Debug:$false
            $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1

            if ($null -ne $ip -and $ip -ne [string]::Empty) {

                $RunList = $ChefRunList
                
                $cmd = {
                    $OriginBootstrapSource = $args[0]
                    $ChefClient = $args[1]    
                    $RunList = $args[2]

                    Start-Process msiexec -ArgumentList '/qn /i c:\windows\temp\ChefClient\chef-client-12.4.1-1.msi ADDLOCAL="ChefClientFeature,ChefServiceFeature"' -Wait

                    If ($env:Path -notmatch 'C:\\opscode\\chef\\bin' -and $env:Path -notmatch 'c:\\opscode\\chef\\embedded\\bin'){
                        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\opscode\chef\bin;C:\opscode\chef\embedded\bin", [System.EnvironmentVariableTarget]::Machine)
                        $env:Path = $env:Path + ";C:\opscode\chef\bin;C:\opscode\chef\embedded\bin"
                    }

                    $KnifeRB= @"
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "$ChefClient"
client_key               "c:\\chef\\$ChefClient.pem"
validation_client_name   "csc-validator"
validation_key           "c:\\chef\\csc-validator.pem"
chef_server_url          "https://ush-p-chf-mstr1.columbia.csc/organizations/csc"
cookbook_path            ["C:\\chef_cookbooks"]
"@
    
                    New-Item ($HOME + '\.chef\') -ItemType Directory
                    $KnifeRB | Out-File ($HOME + '\.chef\knife.rb') -Encoding ascii

                    New-Item ($HOME + '\.chef\trusted_certs\') -ItemType Directory
                    Copy-Item 'C:\Windows\Temp\ChefClient\ush-p-chf-mstr1.columbia.csc.crt' ($HOME + '\.chef\trusted_certs\')

                    New-Item c:\chef -type directory -Force
                    New-Item c:\chef\trusted_certs -type directory -Force
                    Copy-Item ('C:\Windows\Temp\ChefClient\' + $ChefClient + '.pem') c:\chef -Force
                    Copy-Item 'C:\Windows\Temp\ChefClient\client.rb' c:\chef -Force
                    Copy-Item 'C:\Windows\Temp\ChefClient\csc-validator.pem' c:\chef -Force
                    Copy-Item 'C:\Windows\Temp\ChefClient\ush-p-chf-mstr1.columbia.csc.crt' c:\chef\trusted_certs
                    Start-Process chef-client -Wait

                    $FQDN = $env:computername + '.' + $env:userdnsdomain.ToLower()
    
                    Start-Process 'chef-service-manager' -ArgumentList "-a install" -Wait
                    Start-Process 'chef-service-manager' -ArgumentList "-a start" -Wait
                    Start-Process 'knife' -ArgumentList "node run_list add $FQDN $RunList" -Wait

                    Remove-Item c:\chef\csc-validator.pem
                    Remove-Item c:\windows\temp\chefclient\csc-validator.pem
                    Remove-Item ('c:\chef\' + $ChefClient + '.pem')
                }


                $ip = '10.45.203.23'
                $session = New-PSSession -ComputerName $ip -Credential $credential -Verbose:$false
                New-PSDrive -Name 'ChefClient' -Credential $credential -PSProvider FileSystem -Root ('\\' + $ip + '\C$')

                Remove-Item  ('\\' + $ip + '\c$\Windows\Temp\ChefClient\') -Force -Recurse
                Copy-Item ($OriginBootstrapSource + '\chef\clientregistration\prod\') ('\\' + $ip + '\c$\Windows\Temp\ChefClient\') -Force -Recurse
                Invoke-Command -Session $session -ScriptBlock $cmd -ArgumentList @($OriginBootstrapSource,'ccolgan',$RunList) -Verbose:$false
                Remove-PSSession $session -ErrorAction SilentlyContinue
                Remove-PSDrive 'ChefClient' -ErrorAction SilentlyContinue

            } else {
                Write-Error -Message 'No valid IP address returned from VM view. Can not test guest disks'
            }  
        } catch {
            Write-Error -Message 'There was a problem configuring the Chef client'
            Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            write-Error $_
        } finally {
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }

    end {
        Write-Debug -Message 'Ending _SetChefClient()'
    }
}