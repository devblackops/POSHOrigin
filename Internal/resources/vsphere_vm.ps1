#param(
#    $x
#)

#$block = [scriptblock]{
#    # TODO
#    # Add more robust validation
#    # If we didn't specify a power state for the VM (null), power on the VM
#    if ($null -eq $x.options.PowerOnAfterCreation) {
#        $_.options.PowerOnAfterCreation = $true
#    }

#    $provJson = [string]::Empty
#    if ($null -ne $x.options.provisioners) {
#        $provJson = ConvertTo-Json -InputObject $x.options.provisioners -Depth 10
#    }

#    if ($null -eq $provJson) {
#        $provJson = [string]::Empty
#    }

#    POSHOrigin_vSphere_VM $x.Name {
#        Ensure = $x.options.Ensure
#        Name = $x.Name
#        PowerOnAfterCreation = $x.options.PowerOnAfterCreation
#        vCenter = $x.options.vCenter
#        vCenterCredentials = $x.options.secrets.vCenter.credential
#        VMTemplate = $x.options.VMTemplate
#        TotalvCPU = $x.options.TotalvCPU
#        CoresPerSocket = $x.options.CoresPerSocket
#        vRAM = $x.options.vRAM
#        Datacenter = $x.options.Datacenter
#        Cluster = $x.options.Cluster
#        InitialDatastore = $x.options.InitialDatastore
#        Disks = ConvertTo-Json -InputObject $x.options.disks
#        CustomizationSpec = $x.options.CustomizationSpec
#        GuestCredentials = $x.options.secrets.guest.credential
#        IPAMCredentials = $x.options.secrets.ipam.credential
#        IPAMFqdn = $x.options.secrets.ipam.options.fqdn
#        DomainJoinCredentials = $x.options.secrets.domainJoin.credential
#        Networks = ConvertTo-Json -InputObject $x.options.networks
#        Provisioners = $provJson
#    }
#}

#return $block