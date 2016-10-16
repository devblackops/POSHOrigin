
function _GetGenericGitRepo {
    [cmdletbinding()]
    param(
        [string]$Url
    )   

    try {    
        # Make sure 'git.exe' is available
        if (-not (Get-Command -Name 'git.exe') ) {
            Write-Error -Message 'Unable to find [git.exe] command. Is git installed correctly?'
            return
        }

        # Use git to clone repo to temp directory
        $tempDir =  _NewTempDir
        Write-Debug -Message "Temp dir created: [($tempDir.FullName)]"
        Write-Verbose -Message "Cloning repo [$url] to [$($tempDir.FullName)]"    

        # Files to redirect stdout/err to when calling 'git.exe'
        $stdOutPath = Join-Path -Path $tempDir -ChildPath 'stdOut.txt'
        $stdErrPath = Join-Path -Path $tempDir -ChildPath 'stdErr.txt'    
        Write-Debug -Message "stdout log: [($stdOutPath.FullName)]"
        Write-Debug -Message "stderr log: [($stdErrPath.FullName)]"    

        # Call 'git.exe' to clone the repo
        $params = @{
            FilePath = 'git.exe'
            ArgumentList = @("clone $url")
            WorkingDirectory = $tempDir
            RedirectStandardError = $stdErrPath
            RedirectStandardOutput = $stdOutPath
            Wait = $true        
            NoNewWindow = $true
            PassThru = $true        
        }
        $proc = Start-Process @params

        if ($proc.ExitCode -ne 0) {
            $errs = Get-Content -Path $stdErrPath -Raw
            Write-Error -Message $errs
            Remove-Item -Path $stdErrPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $stdOutPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $tempDir -Force
        } else {
            $repoName = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
            $repoPath = (Join-Path -Path $tempDir -ChildPath $repoName)
            Remove-Item -Path $stdErrPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $stdOutPath -Force -ErrorAction SilentlyContinue
            $repoPath
        }
    } catch {
        Write-Error $_
    }
}
