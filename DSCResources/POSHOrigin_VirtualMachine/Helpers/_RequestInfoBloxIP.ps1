function _RequestInfoBloxIP {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Network,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GridServer,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    try {
        Import-Module -Name 'InfoBlox' -Verbose:$false

        Write-Debug "IPAM Server: $GridServer"
        Write-Debug "IPAM Credentials [$($Credential.Username)][$($Credential.GetNetworkCredential().Password)]"

        # Get subnet mask and gateway info from IPAM
        Write-Debug "Getting network [$Network] from IPAM"
        $netInfo = Get-IBNetwork -GridServer $GridServer -Credential $Credential -Network $Network

        # Get the next available IP from IPAM
        Write-Debug "Requesting available IP for network [$Network] from IPAM"
        $IPInfo = Request-IBAvailableIP -GridServer $GridServer -Credential $Credential -Network $Network -Name $Name

        if ($null -ne $IPInfo) {
            Write-Verbose -Message 'Received following IP informatin from IPAM:'
            Write-Verbose -Message ($IPInfo | Format-List -Property * | Out-String)
            $IPInfo | Add-Member -Type NoteProperty -Name 'Gateway' -Value $netInfo.gateway
            $IPInfo | Add-Member -Type NoteProperty -Name 'SubnetMask' -Value $netInfo.subnetMask
            return $IPInfo
        } else {
            Write-Warning -Message 'Unable to reserve IP in IPAM.'
            return $null
        }
    } catch {
        Write-Error -Message 'There was a problem setting the NIC mapping'
        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        Write-error $_
    }
}