
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
            Write-Verbose -Message "Getting resource group [$resourceGroup]"
            $resGroup = Get-AzureRmResourceGroup -Name $ResourceGroup -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if ($resourceGroup) {
                Write-Verbose -Message "Resource group exists"
                try {                    
                    $tempFile = New-TemporaryFile
                    $json = $template | ConvertTo-Json -Depth 100                    
                    $json | Out-File -FilePath $tempFile -Force
                    Write-Verbose -Message "ARM deployment temp file [$($tempFile.Fullname)]"
                    
                    Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $tempFile -ErrorAction Stop
                    Write-Verbose -Message 'ARM deployment validated'
                    New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $tempFile
                    Remove-Item $tempFile -Force
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

    $conn = Connect-AzureRm -Credential $Credential
    
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
    $t.resources += ($Resources | ConvertFrom-Json)
    
    if ($PSBoundParameters.ContainsKey('Parameters')) {
        $t.parameters = ($Parameters | ConvertFrom-Json)    
    } else {
        $t.parameters = $null
    }
    
    if ($PSBoundParameters.ContainsKey('Variables')) {
        $t.Variables = ($Variables | ConvertFrom-Json)    
    } else {
        $t.Variables = $null
    }
    
    if ($PSBoundParameters.ContainsKey('Outputs')) {
        $t.Outputs = ($Outputs | ConvertFrom-Json)    
    } else {
        $t.Outputs = $null
    }

    return $t
}

function New-ArmTemplateStub {    
    return @{
        '$schema' = 'http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
        contentVersion = ''
        parameters = @{}
        variables = @{}
        resources = @()
        outputs = {}
    }
}

Export-ModuleMember -Function *-TargetResource