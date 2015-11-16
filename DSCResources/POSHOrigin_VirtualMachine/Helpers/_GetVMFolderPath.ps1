#http://www.lucd.info/2010/10/21/get-the-folderpath/

function _GetVMFolderPath {
    <#
    .SYNOPSIS
        Returns the folderpath for a folder
    .DESCRIPTION
        The function will return the complete folderpath for
        a given folder, optionally with the "hidden" folders
        included. The function also indicats if it is a "blue"
        or "yellow" folder.
    .NOTES
        Authors:  Luc Dekens
    .PARAMETER Folder
        On or more folders
    .PARAMETER ShowHidden
        Switch to specify if "hidden" folders should be included
        in the returned path. The default is $false.
    .EXAMPLE
        PS> Get-FolderPath -Folder (Get-Folder -Name "MyFolder")
    .EXAMPLE
        PS> Get-Folder | Get-FolderPath -ShowHidden:$true
    #>
    [cmdletbinding()]
    param(
        [parameter(valuefrompipeline = $true,
        position = 0,
        HelpMessage = "Enter a folder")]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl[]]$Folder,
        [switch]$ShowHidden = $false
    )
 
    begin{
        $excludedNames = "Datacenters", "vm", "host"
    }
 
    process{
        $Folder | Foreach-Object {
            $fld = $_.Extensiondata
            $fldType = "yellow"
            if($fld.ChildType -contains "VirtualMachine"){
                $fldType = "blue"
            }
            $path = $fld.Name
            while($fld.Parent){
                $fld = Get-View $fld.Parent -Verbose:$false -Debug:$false
                $fld | fl *
                if((!$ShowHidden -and $excludedNames -notcontains $fld.Name) -or $ShowHidden){
                    $path = $fld.Name + "\" + $path
                }
            }
            $row = "" | Select-Object -Property Name, Path, Type
            $row.Name = $_.Name
            $row.Path = $path
            $row.Type = $fldType
            $row
        }
    }
}


