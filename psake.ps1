properties {
    $sut = '.\POSHOrigin'
    $tests = '.\Tests'
}

task default -depends Analyze, Test

task Analyze {
    $excludedRules = (
        'PSAvoidUsingConvertToSecureStringWithPlainText'
    )
    $saResults = Invoke-ScriptAnalyzer -Path $sut -Severity Error -ExcludeRule $excludedRules -Recurse -Verbose:$false
    if ($saResults) {
        $saResults | Format-Table  
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'        
    }
}

task Test {
    $testResults = Invoke-Pester -Path $tests -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task Deploy -depends Analyze, Test {
    Invoke-PSDeploy -Path '.\psgallery.psdeploy.ps1' -Force -Verbose:$VerbosePreference
}
