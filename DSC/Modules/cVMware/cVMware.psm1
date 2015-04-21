enum Ensure {
   Absent
   Present
}

[DscResource()]
class cVMwareVM {
    [DscProperty(key)]
    [string]$VMName

    [DscProperty(Mandatory)]
    [pscredential]$Credentials

    [DscProperty(Mandatory)]
    [int]$TotalvCPU

    [DscProperty(Mandatory)]
    [int]$CoresPerSocket

    [DscProperty(mandatory)]
    [int]$vRAM

    [DSCProperty()]
    [string]$DiskSpec
    
    [DSCProperty()]
    [string]$VMTemplate 

    [DscProperty(mandatory)]
    [string]$vCenter

    [DscProperty(Mandatory)]
    [string]$Datacenter

    [DscProperty(Mandatory)]
    [string]$InitialDatastore

    [DscProperty()]
    [string]$Cluster

    [DscProperty()]
    [string]$VMHost

    [DscProperty(mandatory)]
    [Ensure]$Ensure

    [bool]$vCenterConnected
    
    [cVMwareVM]Get() {
        $vmConfig = [hashtable]::new()
        $vmConfig.Add('VMName', $this.VMName)
        $vmConfig.Add('Credentials', $this.Credentials)
        $vmConfig.Add('TotalvCPU', $this.TotalvCPU)
        $vmConfig.Add('CoresPerSocket', $this.CoresPerSocket)
        $vmConfig.Add('vRAM', $this.vRAM)
        $vmConfig.Add('DiskSpec', $this.DiskSpec)
        $vmConfig.Add('VMTemplate', $this.VMTemplate)
        $vmConfig.Add('vCenter', $this.vCenter)
        $vmConfig.Add('Datacenter', $this.Datacenter)
        $vmConfig.Add('InitialDatastore', $this.InitialDatastore)
        $vmConfig.Add('Cluster', $this.VMCluster)
        $vmConfig.Add('VMHost', $this.VMHost)
        $vmConfig.Add('Ensure', $this.Ensure)

        # Connect to vCenter
        if (!$this.vCenterConnected) { $this.ConnectTovCenter() }
        
        $vm = FindVM -Name $this.VMName
        
        try {
            if ($vm -ne $null) {
                $vmConfig.Add('Ensure','Present')
                $vmConfig.Add('vRAM', $vm.MemoryGB)
            } else {
                $vmConfig.Add('Ensure','Absent')
            }
        } catch {
            $exception = $_
            Write-Verbose 'Error occurred'
            while ($exception.InnerException -ne $null) {
                $exception = $exception.InnerException
                Write-Verbose $exception.message
            }
        }
        return $vmConfig
    }

    [void]Set() {
        try {

            if (!$this.vCenterConnected) { $this.ConnectTovCenter() }

            if ($this.Ensure -eq [Ensure]::Present) {

                $vm = Get-VM -Name $this.VMName -verbose:$false -ErrorAction SilentlyContinue | select -First 1

                if ($vm -eq $null) {
                    Write-Verbose "Creating VM: $($this.VMName)"
                    $result = $this.CreateVM()
                    if ($result -eq $true) {
                        Write-Verbose 'VM created successfully'
                    } else {
                        throw 'There was a problem creating the VM'
                    }
                } else {
                    # vRAM
                    if ($vm.MemoryGB -ne $this.vRAM) {
                        # It is safe to decrease vRAM is VM is powered off
                        if ($vm.PowerState -eq 'PoweredOn') {
                            # Are we increasing vRAM?
                            if ($vm.MemoryGB -lt $this.vRAM) {
                                write-verbose "Changing $($this.VMName) vRAM to $($this.vRAM)"
                                set-vm -vm $vm -memorygb $($this.vRAM) -confirm:$false -verbose:$false
                            } else {
                                write-error 'Cannot decrease vRAM while VM is powered on'
                            }
                        } else {
                            write-verbose "Changing $($this.VMName) vRAM to $($this.vRAM)"
                            set-vm -vm $vm -memorygb $($this.vRAM) -confirm:$false -verbose:$false
                        }
                    }

                    # VM matches CPU
                    if (($vm.extensiondata.config.hardware.numcpu -ne $this.TotalvCPU) -or ($vm.extensiondata.config.hardware.numcorespersocket -ne $this.CoresPerSocket)) {

                        if ($vm.PowerState -eq 'PoweredOn') {
                            # IS CPU hotadd enabled?
                            if ($VM.extensiondata.config.cpuhotaddenabled) {

                            } else {
                                write-error 'CPU hotadd is disabled on this VM. Cannot increase vCPU while VM is powered on'
                            }
                        } else {
                            # Safe to change vCPU while powerd off
                            write-verbose  "Changing $($this.VMName) vCPU to $($this.TotalvCPU)"
                            $this.SetCPU($vm)
                        }
                    }
                }
            } else {
                Write-Verbose "Removing VM: $($this.VMName)"
            }
        } catch {
            Write-Verbose 'There was a problem setting the resource'
            Write-Verbose "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
        }
    }

    [bool]Test() {

        $checksPassed = $true

        try {
            if (!$this.vCenterConnected) { $this.ConnectTovCenter() }

            $vm = Get-VM -Name $this.VMName -verbose:$false -ErrorAction SilentlyContinue | select -First 1

            #region Go through checks to determine if resource matches desired state

            # VM exists
            if ($vm -ne $null) {
                Write-Verbose -Message "VM: $($this.VMName) was found"
            } else {
                Write-Verbose -Message "VM: $($this.VMName) was not found"
            }                       
            if ($this.Ensure -eq [Ensure]::Present) {
                if ($vm -eq $null) { return $false }
            } else {
                if ($vm -eq $null) { return $true } else { return $false }
            }

            # VM matches memory
            if ($vm.MemoryGB -ne $this.vRAM) {
                write-verbose "$($this.VMName) does not match desired vRAM allocation"
                $checksPassed = $false
            }

            # VM matches CPU
            if (($vm.extensiondata.config.hardware.numcpu -ne $this.TotalvCPU) `
                -or ($vm.extensiondata.config.hardware.numcorespersocket -ne $this.CoresPerSocket)) {

                write-verbose "$($this.VMName) does not match desired vCPU allocation"
                $checksPassed = $false
            }

            if ($checksPassed -eq $true) {
                Write-Verbose 'Checks passed'
                return $true
            } else {
                Write-Verbose 'Checks did not pass'
                return $false
            }
            #endregion
        } catch {
            Write-Verbose 'There was a problem testing the resource'
            Write-Verbose "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            return $false
        }
    }

    #region Helpers    
    [bool]ConnectTovCenter() {
        if (!$this.vCenterConnected) {
            if ((Get-PSSnapin -Registered -Name 'VMware.VimAutomation.Core') -ne $null) {
                try {
                    Add-PSSnapin 'VMware.VimAutomation.Core'
                    Write-Debug 'Added VMware.VimAutomation.Core snapin'
                } catch {
                    throw 'There was a problem loading snapin Vmware.VimAutomation.Core.'
                }
            } else {
                throw 'Vmware.VimAutmation.Core snapin is not installed on this system!'
            }

            try {
                write-Debug "trying to connect to $($this.vCenter)"
                Connect-VIServer -Server $($this.vCenter) `
                                 -User $($this.Credentials.UserName) `
                                 -Password $($this.Credentials.GetNetworkCredential().Password) `
                                 -Force -verbose
                write-Debug "Connected to vCenter: $($this.vCenter)"
                $this.vCenterConnected = $true
                return $true
            } catch {
                throw "There was a problem connecting to vCenter: $($this.vCenter)"
                $this.vCenterConnected = $false                
                return $false
            }
        }    
    }

    [bool]FindVM([string]$vmName) {
        if (!$this.vCenterConnected) { ConnectTovCenter }

        write-verbose "Trying to find VM: $vmName"
        $vm = Get-VM -Name $vmName -verbose:$false -ErrorAction SilentlyContinue
        if ($vm -ne $null) {
            return $true
        } else {
            return $false
        }
    }

    [bool]CreateVM() {
        $template = $null
        $cluster = $null
        $datastore = $null

        if ($this.VMTemplate -ne $null) {
            $template = Get-Template -Name $this.VMTemplate `
                                     -verbose:$false -ErrorAction SilentlyContinue | Select-Object -First 1
            Write-debug "Template: $($template.Name)"
        }

        if ($this.Cluster -ne $null) {
            $cluster = Get-Cluster -Name $this.Cluster `
                                   -verbose:$false -ErrorAction SilentlyContinue | Select-Object -First 1
            Write-debug "Cluster: $($cluster.Name)"
        }

        $datastore = Get-Datastore -Name $this.InitialDatastore `
                                   -verbose:$false -ErrorAction SilentlyContinue | Select-Object -First 1
        write-debug "Datastore: $($datastore.Name)"
        
        $vm = $null
        # Do we have all the information we need to provision the VM?
        if (($template -ne $null) -and ($datastore -ne $null) -and ($cluster -ne $null)) {   

            Write-Verbose "vmname: $($this.VMName)"

            $vm = New-VM -Name $this.VMName `
                         -Template $template `
                         -Datastore $datastore `
                         -ResourcePool $cluster `
                         -DiskStorageFormat Thin `
                         -verbose:$false
        } else {
            Write-Error 'Could not resolve required VMware objects needed to create this VM.'
        }

        if ($vm -ne $null) {
            return $true
        } else {
            return $false
        }
    }

    [bool]SetCPU($vm) {
        [bool]$result = $false

        # If the VM is powered on, we must verify that CPU hotadd
        # is enabled before we can increase the CPU count.
        $task = $null
        if ($vm.PowerState -eq 'PoweredOn') {
            # TODO
            # Deal will powered on VMs and increasing CPU
        } else {
            # It is safe to change the CPU count while powered off
            $spec = New-Object -TypeName Vmware.Vim.VirtualMachineConfigSpec -property @{
                "NumCoresPerSocket" = $this.CoresPerSocket
                "NumCPUs" = $this.TotalvCPU
            }
            $task = $vm.extensiondata.reconfigvm_task($spec)
        }

        # Wait for the task to complete
        $done = $false
        $maxWait = 36 # 3 minutes
        $x = 0
        while (!$done -or ($x -le $maxWait)) {
            $taskResult = get-task -id ('Task-' + $task.value) -verbose:$false
            if ($taskResult.State.toString() -eq 'Success') {
                $done = $true
            } else {
                Start-Sleep -Seconds 5
            }
            $x += 1
        }

        return $result
    }

    #endregion
}