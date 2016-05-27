#Requires -Modules xDSCResourceDesigner

$Name = New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description 'Name of the ARM deployment'
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Required -ValidateSet "Present", "Absent" -Description 'Ensure that the ARM deployment matches'
$Credential = New-xDscResourceProperty -Name Credential -Type PSCredential -Attribute Required -Description 'Credential to connect to Azure Resource Manager'
$Version = New-xDscResourceProperty -Name Version -Type String -Attribute Required -Description 'Version of the ARM template'
$ResourceGroup = New-xDscResourceProperty -Name ResourceGroup -Type String -Attribute Required -Description 'Resource group to deploy ARM template to'
$DeploymentType = New-xDscResourceProperty -Name DeploymentType -Type String -Attribute Write -ValidateSet "Incremental", "Complete" -Description 'ARM deployment type'
$Resources = New-xDscResourceProperty -Name Resources -Type String -Attribute Required -Description 'JSON string of resources to deploy'
$Variables = New-xDscResourceProperty -Name Variables -Type String -Attribute Write -Description 'JSON string of variables to use in deployment'

New-xDscResource -Name POSHOrigin_ARMDeployment -Property @($Name, $Ensure, $Credential, $Version, $ResourceGroup, $DeploymentType, $Resources, $Variables) -ModuleName POSHOrigin -FriendlyName ARMDeployment
