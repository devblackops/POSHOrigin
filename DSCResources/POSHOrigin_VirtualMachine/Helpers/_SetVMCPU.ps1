function _SetVMCPU {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [int]$TotalvCPU,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [int]$CoresPerSocket
    )

    [bool]$result = $false
    $continue = $false

    # If the VM is powered on, we must verify that CPU hotadd
    # is enabled before we can increase the CPU count.    
    if ($vm.PowerState -eq 'PoweredOn') {
        # TODO
        # Deal will powered on VMs and increasing CPU
        Write-Error -Message 'Can not change vCPU while VM is powered on. This will be fixed in a later release.'
        $continue = $false
    } else {
        $continue = $true        
    }

    if ($continue -eq $true) {
        # It is safe to change the CPU count while powered off
        $spec = New-Object -TypeName Vmware.Vim.VirtualMachineConfigSpec -Property @{
            "NumCoresPerSocket" = $CoresPerSocket
            "NumCPUs" = $TotalvCPU
        }

        $task = $null
        if ($CoresPerSocket -ne 0) {
            $sockets = $TotalvCPU / $CoresPerSocket
            Write-Verbose -Message "Changing $($VM.Name) vCPU to $TotalvCPU ($($sockets):$($CoresPerSocket))"
            $task = $vm.extensiondata.reconfigvm_task($spec)
        } else {
            throw 'CoresPerSocket can not be 0'
        }

        # Wait for the task to complete
        $done = $false
        $maxWait = 36 # 3 minutes
        $x = 0
        if ($null -ne $task) {
            while (!$done -or ($x -le $maxWait)) {
                $taskResult = Get-Task -Id ('Task-' + $task.value) -Verbose:$false
                if ($taskResult.State.ToString().ToLower() -eq 'success') {
                    $done = $true
                    $result = $true
                } else {
                    Start-Sleep -Seconds 5 -Verbose:$false
                }
                $x += 1
            }
        }
    }

    return $result
}