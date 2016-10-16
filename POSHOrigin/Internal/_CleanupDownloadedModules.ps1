
function _CleanupDownloadedModules.ps1 {
    [cmdletbinding()]
    param()

    # Remove any downloaded git-based modules
    if ($script:gitModulesProcessed.Keys.Count -gt 0) {
        foreach ($moduleSource in $script:gitModulesProcessed.Keys) {
            $modulePath = $script:gitModulesProcessed[$ModuleSource]
            $parent = Split-Path -Path $modulePath -Parent
            Write-Verbose -Message "Removing temporary module path [$parent] for module [$moduleSource]"                    
            Remove-Item -Path $parent -Force -Recurse
        }
    }
    $script:gitModulesProcessed = @{}
}
