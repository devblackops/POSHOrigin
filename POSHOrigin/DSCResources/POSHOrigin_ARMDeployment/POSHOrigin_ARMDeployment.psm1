
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(Mandatory)]
        [ValidateSet("Present","Absent")]
        [string]$Ensure,

        [parameter(Mandatory)]
        [pscredential]$Credential,
        
        [parameter(Mandatory)]
        [string]$Version,
        
        [parameter(Mandatory)]
        [string]$ResourceGroup,
        
        [parameter(Mandatory)]
        [string]$Resources,
        
        [string]$Variables
    )

    return @{
        Name = $Name
        Ensure = $Ensure
        Version = $Version
        ResourceGroup = $ResourceGroup
        Resources = $Resources
        Variables = $Variables        
    }
}

function Set-TargetResource {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(Mandatory)]
        [ValidateSet("Present","Absent")]
        [string]$Ensure,
        
        [parameter(Mandatory)]
        [pscredential]$Credential,

        [parameter(Mandatory)]
        [string]$Version,
        
        [parameter(Mandatory)]
        [string]$ResourceGroup,
        
        [parameter(Mandatory)]
        [string]$Resources,
        
        [string]$Variables
    )
    
    Connect-AzureRm -Credential $Credential
   
    switch ($Ensure) {
        'Present' {
            $template = New-ArmTemplate -Version $Version -Resources $Resources -Variables $Variables         
            
            $resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroup -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if ($resourceGroup) {
            
                $tempFile = New-TemporaryFile
                try {                                        
                    $template | Out-File -FilePath $tempFile                    
                    Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $tempFile
                    New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $tempFile
                } catch {
                    Write-Error -Message 'ARM template does not validate!'
                    Write-Error $_
                    Remove-Item $tempFile -Force
                }                
            } else {
                throw "Resource group [$ResourceGroup] does not exist!"
            }
        }
        'Absent' {
            
        }
    }

}

function Test-TargetResource {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(Mandatory)]
        [ValidateSet("Present","Absent")]
        [string]$Ensure,
        
        [parameter(Mandatory)]
        [pscredential]$Credential,

        [parameter(Mandatory)]
        [string]$Version,
        
        [parameter(Mandatory)]
        [string]$ResourceGroup,
        
        [parameter(Mandatory)]
        [string]$Resources,
        
        [string]$Variables
    )

    return $false
}

function Connect-AzureRm {
    param(
        [parameter(Mandatory)]
        [pscredential]$Credential
    )
    
    Add-AzureRmAccount -Credential $Credential
}

function New-ArmTemplate {
    param(
        [string]$Version = '1.0.0.0',

        [parameter(Mandatory)]
        [string]$Resources,

        [string]$Parameters,
        
        [string]$Variables,

        [string]$Outputs
    )

    $t = New-ArmTemplateStub
    $t.contentVersion = $Version
    $t.resources += $Resources
    
    if ($PSBoundParameters.ContainsKey('Parameters')) {
        $t.parameters = $Parameters | ConvertFrom-Json    
    }
    
    if ($PSBoundParameters.ContainsKey('Variables')) {
        $t.Variables = $Variables | ConvertFrom-Json    
    }
    
    if ($PSBoundParameters.ContainsKey('Outputs')) {
        $t.Outputs = $Outputs | ConvertFrom-Json    
    }

    $t
}

function New-ArmTemplateStub {    
    @{
        '$schema' = 'http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
        contentVersion = ''
        parameters = @{}
        variables = @{}
        resources = @()
        outputs = {}
    }    
}

Export-ModuleMember -Function *-TargetResource