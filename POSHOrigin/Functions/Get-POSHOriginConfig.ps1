function Get-POSHOriginConfig {
    <#
        .SYNOPSIS
            Reads and processes a POSHOrigin configuration file.
        .DESCRIPTION
            Reads and processes a POSHOrigin configuration file and returns the result as one or more PowerShell custom objects containing the
            required options that when passed to a POSHOrigin DSC resource can provision the infrastructure the DSC resource represents.
        .PARAMETER Path
            The relative or absolute path(s) of the configuration files or folders to be processed
        .PARAMETER Recurse
            Recursively process subfolders and files
        .EXAMPLE
            Read the configuration contained in vm_config.ps1 into a variable.
            
            $config = Get-POSHOriginConfig -Path '.\vm_config.ps1' -Verbose
        .EXAMPLE
            Read all the configurations in folder MyConfigs into a variable.
            
            $configs = '.\MyConfigs' | Get-POSHOriginConfig -Verbose
        .EXAMPLE        
            Read the configurations my_vm.ps1 and my_vips into a variable.
            
            $configs = '.\my_vm.ps1', 'my_vips.ps1' | Get-POSHOriginConfig -Verbose
        .EXAMPLE
            Recursively read the configurations contained in the folder my_configs.
            $configs = '.\MyConfigs' | Get-POSHOriginConfig -Recurse -Verbose
    #>
    [cmdletbinding(HelpUri='https://github.com/devblackops/POSHOrigin/wiki/Get-POSHOriginConfig')]
    param(
        [parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('FullName')]
        [ValidateScript({Test-Path $_})]
        [string[]]$Path = (Get-Location).Path,

        [switch]$Recurse
    )

    begin {
        $script:credentialCache = @{}
        $script:modulesToProcess = @{}
        $script:resourceCache = @{}
    }

    process {
        foreach ($item in $Path) {
            # Load in the configurations
            $item = Resolve-Path $item
            if (Test-Path -Path $item) {                
                $configData = @(@(_LoadConfig -Path $item -Recurse:$Recurse) | _SortByDependency)
                Write-Verbose -Message ([string]::Empty)
                Write-Verbose -Message ("Created $($configData.Count) resource objects")
                return $configData
            } else {
                Write-Error -Message ($msgs.invalid_path -f $path)
            }
        }
    }

    end {

        # Remove any downloaded git-based modules
        _CleanupDownloadedModules.ps1        
        
        $script:credentialCache = @{}
        $script:modulesToProcess = @{}
        $script:resourceCache = @{}
    }
}
