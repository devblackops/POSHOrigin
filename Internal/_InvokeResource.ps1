function _InvokeResource {
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        [string]$Type,

        [parameter(mandatory)]
        [psobject]$Options
    )

    #$moduleName = "POSHOrigin"
    #$resourceName = "VirtualMachine"
    #$resource = Get-DscResource -Module $moduleName -Name $resourceName -ErrorAction SilentlyContinue
    #if ($null -ne $resource) {
    #    $invokeFile = "$($resource.ParentPath)\Invoke.ps1"
    #    if (Test-Path -Path $invokeFile) {
    #        Write-Verbose "Calling DSC invoke script: $invokeFile"
    #        & $invokeFile -x $Options
    #    } else {
    #        throw "Unknown resource type [$Type]"
    #    }
    #} else {
    #    throw "Unable to find DSC resource [$resourceName]"
    #}

    $resourceFile = "$moduleRoot\Internal\resources\$Type.ps1"
    if (Test-Path -Path $ResourceFile) {
        & $resourceFile -x $Options
    } else {
        Write-Error -Message "Unknown resource type [$Type]"
    }
}