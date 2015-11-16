# Taken with love from http://www.lucd.info/2012/05/18/folder-by-path/
# with a few minor modifications

function _GetVMFolderByPath{
    <#
    .SYNOPSIS  Retrieve folders by giving a path
    .DESCRIPTION The function will retrieve a folder by it's
        path. The path can contain any type of leave (folder or datacenter).
    .NOTES  Author:  Luc Dekens
    .PARAMETER Path
        The path to the folder.
        This is a required parameter.
    .PARAMETER Path
        The path to the folder.
        This is a required parameter.
    .PARAMETER Separator
        The character that is used to separate the leaves in the
        path. The default is '/'
    .EXAMPLE
        PS> Get-FolderByPath -Path "Folder1/Datacenter/Folder2"
    .EXAMPLE
        PS> Get-FolderByPath -Path "Folder1>Folder2" -Separator '>'
    #> 
    param(
        [CmdletBinding()]
        [parameter(Mandatory)]
        [System.String[]]$Path,

        [char]$Separator = '/'
    )
 
    process{
        if((Get-PowerCLIConfiguration).DefaultVIServerMode -eq 'Multiple') {
            $vcs = $defaultVIServers
        } else{
            $vcs = $defaultVIServers[0]
        }
 
        foreach($vc in $vcs) {
            foreach($strPath in $Path) {
                $root = Get-Folder -Name Datacenters -Server $vc
                $strPath.Split($Separator) | Foreach-Object {
                    $root = Get-Inventory -Name $_ -Location $root -Server $vc -NoRecursion
                    if((Get-Inventory -Location $root -NoRecursion | Select -ExpandProperty Name) -contains "vm"){
                        $root = Get-Inventory -Name 'vm' -Location $root -Server $vc -NoRecursion
                    }
                }
                $root | where {$_ -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl]} | Foreach-Object {
                    Get-Folder -Name $_.Name -Location $root.Parent -Server $vc
                }
            }
        }
    }
}