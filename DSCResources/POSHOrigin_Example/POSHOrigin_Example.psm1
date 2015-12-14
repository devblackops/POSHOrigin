#Requires -Version 5.0

enum Ensure {
    Absent
    Present
}

[DscResource()]
class POSHFolder {
    [DscProperty(key)]
    [string]$Name

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present

    [DscProperty(Mandatory)]
    [string]$Path

    [DscProperty(NotConfigurable)]
    [string]$FullPath

    [DscProperty(NotConfigurable)]
    [bool]$Exists

    [POSHFolder]Get() {
        $folder = [POSHFolder]::new()
        $folder.Name = $this.Name
        $folder.Ensure = $this.Ensure
        $folder.Path = $this.Path
        $folder.FullPath = Join-Path -Path $folder.Path -ChildPath $folder.Name
        $folder.Exists = (Test-Path -Path $folder.FullPath)
        return $folder
    }

    [void]Set() {
        $folder = $this.Get()
        Write-Verbose -Message "Creating folder: $($folder.FullPath)"
        New-Item -ItemType Directory -Path $folder.FullPath -Force
    }

    [bool]Test() {
        $folder = $this.Get()
        if ($folder.Exists) {
            Write-Verbose -Message 'Folder exists'
        } else {
            Write-Verbose -Message 'Folder does not exist'
        }
        return $folder.Exists
    }
}

[DscResource()]
class POSHFile {
    [DscProperty(key)]
    [string]$Name

    [DscProperty(Mandatory)]
    [Ensure]$Ensure = [Ensure]::Present

    [DscProperty(Mandatory)]
    [string]$Path

    [DscProperty()]
    [string]$Contents

    [DscProperty(NotConfigurable)]
    [string]$FullPath

    [DscProperty(NotConfigurable)]
    [bool]$Exists

    [DscProperty(NotConfigurable)]
    [string]$CurrentContents

    [DscProperty(NotConfigurable)]
    [bool]$ContentsMatch

    [POSHFile]Get() {
        $file = [POSHFile]::new()
        $file.Name = $this.Name
        $file.Ensure = $this.Ensure
        $file.FullPath = Join-Path -Path $this.Path -ChildPath $this.Name
        $file.Contents = $this.Contents
        if (Test-Path -Path $file.FullPath) {
            $file.Exists = $true
            $file.CurrentContents = Get-Content -Path $file.FullPath -Raw
            if ($file.CurrentContents -eq $this.Contents) {
                $file.ContentsMatch = $true
            } else {
                $file.ContentsMatch = $false
            }
        } else {
            $file.Exists = $false
            $file.CurrentContents = [string]::Empty
            $file.ContentsMatch = $false
        }

        return $file
    }

    [void]Set() {
        $file = $this.Get()
        if ($file.Exists) {
            if (-Not $file.ContentsMatch) {
                Write-Verbose -Message "Setting content on file: $($file.FullPath)"
                Set-Content -Path $file.FullPath -Value $file.Contents
            }
        } else {
            Write-Verbose -Message "Creating file: $($file.FullPath)"
            New-Item -Path $file.FullPath -ItemType File -Force
            Write-Verbose -Message "Setting content on file: ($file.FullPath)"
            Set-Content -Path $file.FullPath -Value $file.Contents -Force
        }
    }

    [bool]Test() {
        $file = $this.Get()
        Write-Verbose -Message "Testing for file: $($file.FullPath)"
        if ($file.Exists) {
            # File exists, does the content match?
            if ($file.CurrentContents -ne $this.Contents) {
                Write-Verbose -Message 'File exists but does not match content'
                return $false
            } else {
                Write-Verbose -Message 'File exists and matches content'
                return $true
            }
        } else {
            Write-Verbose -Message 'File does not exist'
            return $false
        }
    }
}
