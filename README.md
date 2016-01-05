[![Build status](https://ci.appveyor.com/api/projects/status/n6x8uxguk8tj72bw?svg=true)](https://ci.appveyor.com/project/devblackops/poshorigin)

# POSHOrigin
POSHOrigin is a PowerShell 5 based framework for creating / managing infrastructure objects via custom DSC resources.

## Overview
Infrastructure as Code, or Programmable Infrastructure as some people call it, is meant to describe your infrastructure as an executable configuration in the form of code and is an important concept when thinking about DevOps. Once your infrastructure is described in this way, it can be version controlled, allowing you to see changes over time (this can also serve as a form of backup for your infrastructure).

The configuration files and code that describes your infrastructure has the added benefit as acting as documentation. We all know that traditional documentation in the form of Visio diagrams and Word documents are essentially obsolete the minute that new server or application enters production. Inevitably something in the environment is manually changed and nobody bothers or remembers to update the documentation. With Infrastructure as Code, you make changes to the environment by CHANGING THE DOCUMENTATION. Manually making changes to infrastructure is counter to the Infrastructure as Code concept.

## How does it work?
POSHOrigin is a framework to read and execute the desired configuration of your infrastructure resources. POSHOrigin uses PowerShell DSC as the engine to test and remediate your infrastructure via custom DSC modules/resources that do the heavy lifting to bring your Infrastructure into the desired state.

## What does a configuration file look like?
A typical configuration to create a VM in VMware vSphere would look like the code below. When executed, POSHOrigin will use a custom DSC resource to test that a VM exists with the name 'VM01' and if not, will use PowerCLI to provision the VM with the parameters provided. If a VM named 'VM01' already exists, then DSC resource will bring it into the desired state specified in the configuration (vCPU, vRAM, disk).

###### vm_config.ps1
```PowerShell
resource 'poshorigin_vsphere:vm' 'VM01' @{
    description = 'Test VM'
    defaults = '.\my_vm_defaults.psd1'
}
```

Here is another type of configuration that will provision a Citrix NetScaler server resource, as well as a VIP. Notice that you can define more than one resource in the same file. You denote the type of resource you would like to provision as the first parameter to the **resource** function. Below we are specifying that we are creating a **LBServer** resource from the POSHOrigin_**NetScaler** DSC module and giving it a name of 'VM01' with the provided parameters.

###### ns_config.ps1

```PowerShell
resource 'NetScaler:LBServer' 'VM01' @{
    description = 'this is a comment'
    defaults = '.\my_ns_defaults.psd1'
    ipAddress = '192.168.100.200'
}

resource 'NetScaler:LBVirtualServer' 'VM01_VIP' @{
    description = 'this is a comment'
    defaults = '.\my_ns_defaults.psd1'
    ipAddress = '192.168.100.100'
    port = 80
    serviceType = 'HTTP'
    lbMethod = 'ROUNDROBIN'
}
```

## How do I execute a configuration?
Once you have written the configuration for the type of resource you would like to provision, you can read, test, and execute it with the commands below.

This will read in the **vm_config.ps1** file and process the contents. What is returned is a PowerShell custom object (or array of custom objects if you specified more than one resource in the file) will all the options and credentials required that will later be passed to DSC to compile a configuration.

```PowerShell
# Read the configuration into a variable
$x = Get-POSHOriginConfig -Path .\vm_config.ps1 -Verbose
```

Here we are passing the variable that was created from the code above and compiling a DSC configuration that will be applied to the local machine. In this case we are just going to **test** the configuration (run the Test function of DSC). No changes will be applied to infrastructure.

```PowerShell
# Test the configuration
$x | Invoke-POSHOrigin -Verbose -WhatIf
```

Here we are going to test that the infrastructure resources are in the desired state, modify them if they already exist but don't match, or create any resources that don't exist.
```PowerShell
# Invoke the configuration
$x | Invoke-POSHOrigin -Verbose
```

## More Information
Please check out the [Wiki](https://github.com/devblackops/POSHOrigin/wiki) for further information.
