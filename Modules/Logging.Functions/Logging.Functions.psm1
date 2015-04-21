


#=============================================
# Rotate log file if it exists.
#=============================================
Function New-Log {
    Param ([string]$logFile,
    [switch]$Rotate)
	
    if ($Rotate) {
        #Rotate previous log if it exists
        if (Test-Path -Path $logFile) {
            $file = Get-Item $logFile
            $dtModified = $file.LastWriteTime.ToShortDateString().Replace('/','_')
            $fileName = $file.ToString()
            $arrtmp = $fileName.Split('.')
            $strNewName = $arrtmp[0] + '_' + $dtModified + '.' + $arrtmp[1]
            if (Test-Path -Path $strNewName) {
                Remove-Item $strNewName
            }
            Move-Item -path $file -destination $strNewName
            New-Item $logFile -ItemType 'file' | Out-Null
        } else {
            $text = 'Cannot rotate file: ' + $logFile + '.  File not found.  Creating new file.'
            Write-Error $text
            New-Item $logFile -ItemType 'file' | Out-Null	
        }
    } else {
        New-Item $logFile -ItemType 'file' | Out-Null
    }
}

#=============================================
# Write text to log file.
#=============================================
Function Write-Log {
    [CmdletBinding()]
    Param([Parameter(Mandatory=$true)][string]$LogFile,
          [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Text,
          [Parameter(Mandatory=$false)][string]$Status,
          [Parameter(Mandatory=$false)][switch]$OutConsole) 

    Process {
        $dtNow = Get-Date
        $Text = $dtNow.ToShortDateString() + ' ' + $dtNow.ToShortTimeString() + ' - ' + $Text 
    
        if ($OutConsole) { Write-Host $Text }
	
        if ((Test-Path $LogFile) -eq $true) {
            $Text | Out-File -Append $LogFile		
        } else {
            $Text | Out-File $LogFile
        }
    }
}

Export-ModuleMember New-Log, Write-Log