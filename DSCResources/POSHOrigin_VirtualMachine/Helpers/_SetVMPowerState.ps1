function _SetVMPowerState {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm
    )

    if ($vm.PowerState -eq 'PoweredOn') {
        return $true
    } else {
        try {
            Write-Verbose -Message 'Powering on VM'
            Start-VM -VM $vm -Verbose:$false -Debug:$false
            
            <#
            $t = Start-VM -VM $vm -RunAsync -Verbose:$false -Debug:$false          
            # Wait for task to complete
            while ($t.State.ToString().ToLower() -eq 'running') {
                Start-Sleep -Seconds 10
                $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
            }
            $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
            if ($t.State.ToString().ToLower() -eq 'success') {
                return $true
            } else {
                Write-Warning -Message 'VM failed to power on'
                return $false
            }
            #>
        } catch {
            Write-Warning -Message 'VM failed to power on'
            return $false
        }
    }
}