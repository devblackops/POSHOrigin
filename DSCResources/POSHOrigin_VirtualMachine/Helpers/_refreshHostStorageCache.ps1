function _RefreshHostStorageCache {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    try {
        #$vmView = $vm | Get-View -Verbose:$false

        $t = Get-VM -Id $vm.Id -Verbose:$false -Debug:$false
        $ip = $t.Guest.IPAddress | Where-Object { ($_ -notlike '169.*') -and ( $_ -notlike '*:*') } | Select-Object -First 1

        if ($null -ne $ip -and $ip -ne [string]::Empty) {            
            #$cim = New-CimSession -ComputerName $ip -Credential $Credential -Verbose:$false
            $session = New-PSSession -ComputerName $ip -Credential $credential -Verbose:$false

            Write-Debug 'Refreshing disks on guest'
            Invoke-Command -Session $session -ScriptBlock { Update-HostStorageCache } -Verbose:$false
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
            #Update-HostStorageCache -CimSession $cim -Verbose:$false
        } else {
            Write-Error -Message 'No valid IP address returned from VM view. Can not update guest storage cache'
        }
    } catch {
        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        Write-Error -Message 'There was a problem updating the guest storage cache'
        Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        write-Error -Exception $_
    }
}