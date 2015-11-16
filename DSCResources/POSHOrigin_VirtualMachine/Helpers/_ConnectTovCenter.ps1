function _ConnectTovCenter {
    [cmdletbinding()]
    param(
        [string]$vCenter,
        [pscredential]$Credential
    )

    #region Using PowerCLI module
    # Make sure PowerCLI modules are in the PSModulePath
    $p = [Environment]::GetEnvironmentVariable("PSModulePath")
    if ($p -notcontains '*PowerCLI*') {
        $p += ";C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Modules\"
        [Environment]::SetEnvironmentVariable("PSModulePath",$p)
    }
   
    if ($null -ne (Get-Module -Name VMware.VimAutomation* -ListAvailable -ErrorAction SilentlyContinue -Verbose:$false)) {
        Import-Module Vmware.VimAutomation.Sdk -Verbose:$false
        Import-Module VMware.VimAutomation.Core -Verbose:$false
        Import-Module VMware.VimAutomation.Vds -Verbose:$false
    } else {
        Throw 'VMware PowerCLI modules do not appear to be installed on this system.'
    }
    #endregion

    #region PowerCLI snapin
    #if ((Get-PSSnapin -Registered -Name 'VMware.VimAutomation.Core') -ne $null) {
    #    try {
    #        Add-PSSnapin -Name 'VMware.VimAutomation.Core'
    #        Write-Debug -Message 'Added VMware.VimAutomation.Core snapin'
    #    } catch {  
    #       throw 'Unable to load VMWare.VimAutomation.Core snapin'
    #    }
    #} else {
    #    throw 'Vmware.VimAutmation.Core snapin is not installed on this system!'
    #}
    #endregion

    try {
        Write-Debug -Message "Trying to connect to $vCenter"
        Connect-VIserver -Server $vCenter -Credential $Credential -Force -Verbose:$false -Debug:$false -WarningAction SilentlyContinue
        Write-Debug -Message "Connected to vCenter: $vCenter"
        return $true
    } catch {
        return $false
    }
}