#param(
#    $x
#)

##Import-DscResource -ModuleName POSHOrigin_NetScaler

#    if ($null -eq $x.options.State) {
#        $x.options | Add-Member -MemberType NoteProperty -Name State -Value 'ENABLED'
#    }

#    LBServer $x.Name {
#        Ensure = $x.options.Ensure
#        Name = $x.Name
#        NetScalerFQDN = $x.options.netscalerfqdn
#        Credential = $x.options.secrets.AdminUser.Credential
#        IPAddress = $x.options.IPAddress
#        TrafficDomainId = $x.options.TrafficDomainId
#        Comments = $x.description
#        State = $x.options.State
#    }
