properties {
    $projectRoot = $ENV:BHProjectPath
    if(-not $projectRoot) {
        $projectRoot = $PSScriptRoot
    }

    $sut = "$projectRoot\POSHOrigin"
    $tests = "$projectRoot\Tests"

    $psVersion = $PSVersionTable.PSVersion.Major
}

task default -depends Deploy

task Init {
    "`nSTATUS: Testing with PowerShell $psVersion"
    "Build System Details:"
    Get-Item ENV:BH*

    $modules = 'Pester', 'PSDeploy', 'PSScriptAnalyzer'
    Install-Module $modules -Repository PSGallery -Confirm:$false -ErrorAction Stop
    Import-Module $modules -Verbose:$false -Force
}

task Test -Depends Init, Analyze, Pester

task Analyze {
    # Modify PSModulePath of the current PowerShell session.
    # We want to make sure we always test the development version of the resource
    # in the current build directory.
    $origModulePath = $env:PSModulePath
    $newModulePath = $origModulePath
    if (($newModulePath.Split(';') | Select-Object -First 1) -ne $projectRoot) {
        # Add the project root to the beginning if it is not already at the front.
        $env:PSModulePath = "$projectRoot;$env:PSModulePath"
    }

    $excludedRules = (
        'PSAvoidUsingConvertToSecureStringWithPlainText'
    )
    $saResults = Invoke-ScriptAnalyzer -Path $sut -Severity Error -ExcludeRule $excludedRules -Recurse -Verbose:$false

    # Restore PSModulePath
    if ($origModulePath -ne $env:PSModulePath) {
        $env:PSModulePath = $origModulePath
    }

    if ($saResults) {
        $saResults | Format-Table
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

task Pester {
    if(-not $ENV:BHProjectPath) {
        Set-BuildEnvironment -Path $PSScriptRoot\..
    }
    Remove-Module $ENV:BHProjectName -ErrorAction SilentlyContinue
    Import-Module (Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -Force

    $testResults = Invoke-Pester -Path $tests -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task Deploy -depends Test {
    # Gate deployment
    if( $ENV:BHBuildSystem -ne 'Unknown' -and
        $ENV:BHBranchName -eq "master" -and
        $ENV:BHCommitMessage -match '!deploy'
    ) {
        $params = @{
            Path = "$projectRoot\module.psdeploy.ps1"
            Force = $true
            Recurse = $false
        }

        Invoke-PSDeploy @Params
    } else {
        "Skipping deployment: To deploy, ensure that...`n" +
        "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
        "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
        "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)"
    }
}
