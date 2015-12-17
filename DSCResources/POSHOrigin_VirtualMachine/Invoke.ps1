<#
    This script expects to be passed a psobject with all the needed properties
    in order to invoke a 'VirtualMachine' DSC resource.
#>
param(
    $Options
)

# TODO
# Add more robust validation
# If we didn't specify a power state for the VM (null), power on the VM
if ($null -eq $Options.options.PowerOnAfterCreation) {
    $_.options.PowerOnAfterCreation = $true
}

$provJson = ''
if ($null -ne $Options.options.provisioners) {
    $provJson = ConvertTo-Json -InputObject $Options.options.provisioners -Depth 999
}

if ($null -eq $provJson) {
    $provJson = ''
}

$hash = @{
    Ensure = $Options.options.Ensure
    Name = $Options.Name
    PowerOnAfterCreation = $Options.options.PowerOnAfterCreation
    vCenter = $Options.options.vCenter
    vCenterCredentials = $Options.options.secrets.vCenter.credential
    VMTemplate = $Options.options.VMTemplate
    TotalvCPU = $Options.options.TotalvCPU
    CoresPerSocket = $Options.options.CoresPerSocket
    vRAM = $Options.options.vRAM
    Datacenter = $Options.options.Datacenter
    Cluster = $Options.options.Cluster
    InitialDatastore = $Options.options.InitialDatastore
    Disks = ConvertTo-Json -InputObject $Options.options.disks -Depth 999
    CustomizationSpec = $Options.options.CustomizationSpec
    GuestCredentials = $Options.options.secrets.guest.credential
    IPAMCredentials = $Options.options.secrets.ipam.credential
    IPAMFqdn = $Options.options.secrets.ipam.options.fqdn
    DomainJoinCredentials = $Options.options.secrets.domainJoin.credential
    Networks = ConvertTo-Json -InputObject $Options.options.networks -Depth 999
    ChefRunlist = $Options.options.ChefRunList
    Provisioners = $provJson
}

return $hash
