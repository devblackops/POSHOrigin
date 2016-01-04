
function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $folder = Get-FolderStatus @PSBoundParameters
    return $folder
}

function Set-TargetResource {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
   
    $folder = Get-FolderStatus @PSBoundParameters

    switch ($Ensure) {
        'Present' {
            if (-Not $folder.Exists) {
                Write-Verbose -Message "Creating folder: $($folder.FullPath)"
                New-Item -ItemType Directory -Path $folder.FullPath -Force
            }
        }
        'Absent' {
            if ($folder.Exists) {
                Remove-Item -Path $folder.FullPath -Force -Confirm:$false
            }
        }
    }
}

function Test-TargetResource {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $folder = Get-FolderStatus @PSBoundParameters

    switch ($Ensure) {
        'Present' {
            return $folder.Exists
        }
        'Absent' {
            return -Not $folder.Exists
        }
    }
}

function Get-FolderStatus {
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(Mandatory)]
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure,

        [parameter(Mandatory)]
        [string]$Path
    )

    $returnValue = @{
        Name = $Name
        Ensure = $Ensure
        FullPath = (Join-Path -Path $Path -ChildPath $Name)
        Exists = Test-Path -Path (Join-Path -Path $Path -ChildPath $Name)
    }

    return $returnValue
}

Export-ModuleMember -Function *-TargetResource
