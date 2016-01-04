
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
        $Path,

        [System.String]
        $Contents
    )

    $fileStatus = Get-FileStatus @PSBoundParameters
    return $fileStatus
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
        $Path,

        [System.String]
        $Contents
    )
   
    $file = Get-FileStatus @PSBoundParameters

    switch ($Ensure) {
        'Present' {
            if ($file.Exists) {
                if (-Not $file.ContentsMatch) {
                    Write-Verbose -Message "Setting content on file: $($file.FullPath)"
                    Set-Content -Path $file.FullPath -Value $file.Contents
                }
            } else {
                Write-Verbose -Message "Creating file: $($file.FullPath)"
                New-Item -Path $file.FullPath -ItemType File -Force
                Write-Verbose -Message "Setting content on file: ($file.FullPath)"
                Set-Content -Path $file.FullPath -Value $file.Contents -Force -NoNewline
            }
        }
        'Absent' {
            if ($file.Exists) {
                Write-Verbose -Message "Removing file: $($file.FullPath)"
                Remove-Item -Path $file.FullPath -Force -Confirm:$false
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
        $Path,

        [System.String]
        $Contents
    )

    $file = Get-FileStatus @PSBoundParameters

    switch ($Ensure) {
        'Present' {
            if ($file.Exists -and $file.ContentsMatch) {
                return $true
            } else {
                return $false
            }
        }
        'Absent' {
            if ($file.Exists) {
                return $false
            }
        }
    }
}

function Get-FileStatus {
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(Mandatory)]
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure,

        [parameter(Mandatory)]
        [string]$Path,

        [String]$Contents
    )

    $returnValue = @{
        Name = $Name
        Ensure = $Ensure
        FullPath = (Join-Path -Path $Path -ChildPath $Name)
        Contents = $Contents
    }

    if (Test-Path -Path $returnValue.FullPath) {
        $returnValue.Exists = $true
        $returnValue.CurrentContents = Get-Content -Path $returnValue.FullPath -Raw
        if ($returnValue.CurrentContents -eq $returnValue.Contents) {
            $returnValue.ContentsMatch = $true
        } else {
            $returnValue.ContentsMatch = $false
        }
    } else {
        $returnValue.Exists = $false
        $returnValue.CurrentContents = [string]::Empty
        $returnValue.ContentsMatch = $false
    }

    if ($returnValue.Exists) {
        Write-Verbose -Message "File: $($returnValue.FullPath) exists"
    } else {
        Write-Verbose -Message "File: $($returnValue.FullPath) does not exist"
    }

    if ($returnValue.ContentsMatch) {
        Write-Verbose -Message "Contents match"
    } else {
        Write-Verbose -Message "Contents do not match"
    }


    return $returnValue
}

Export-ModuleMember -Function *-TargetResource