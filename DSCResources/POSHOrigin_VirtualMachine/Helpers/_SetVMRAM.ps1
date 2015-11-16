function _SetVMRAM {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [int]$RAM
    )

    if ($vm.MemoryGB -ne $RAM) {

        $continue = $false

        # If VM is powered on, make sure we are increasing the RAM
        # TODO ADD check for hotadd
        if (($vm.PowerState -eq 'PoweredOn')) {
            # Are we increasing vRAM?
            if ($vm.MemoryGB -lt $RAM) {                
                $continue = $true                
            } else {
                Write-Error 'Cannot decrease vRAM while VM is powered on'
            }
        } else {
            $continue = $true
        }

        # Set RAM if determined safe to do so
        if ($continue -eq $true) {
            try {
                Write-Verbose -Message "Changing $($VM.Name) vRAM to $($RAM)"
                Set-VM -VM $vm -MemoryGB $($RAM) -Confirm:$false -Verbose:$false
            } catch {
                Write-Error -Message 'Failed to set vRAM'
                return $false
            }
            
            <#            
            $t = Set-VM -VM $vm -MemoryGB $($RAM) -RunAsync -Confirm:$false -Verbose:$false
            while ($t.State.ToString().ToLower() -eq 'running') {
                Start-Sleep -Seconds 5
                $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false
            }
            $t = Get-Task -Id $t.Id -Verbose:$false -Debug:$false

            if ($t.State.ToString().ToLower() -eq 'success') {
                $vm = Get-VM -Id $t.Result.Vm -Verbose:$false -Debug:$false
            }
            #>
        }
    }
}