function _InvokeResource {
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        [string]$Module,

        [parameter(mandatory)]
        [string]$Resource,

        [parameter(mandatory)]
        [psobject]$Options
    )

    $type = $Module + "_" + $Resource

    # Try to find the DSC resource
    #$dscResource = Get-DscResource -Name $Resource -Module $Module -ErrorAction SilentlyContinue
    #if (-Not $dscResource) {
    #    $dscResource = Get-DscResource -Name $Resource -Module "POSHOrigin_$Module" -ErrorAction SilentlyContinue
    #}

    $resourceFile = "$moduleRoot\Internal\resources\$Type.ps1"
    if (Test-Path -Path $resourceFile) {
       & $resourceFile -x $Options
    } else {
        Write-Error -Message "Unknown resource type [$resourceFile]"
    }

    # Try to find the DSC resource
    #$dscResource = Get-DscResource -Name $Resource -Module $Module -ErrorAction SilentlyContinue
    #if (-Not $dscResource) {
    #    $dscResource = Get-DscResource -Name $Resource -Module "POSHOrigin_$Module" -ErrorAction SilentlyContinue
    #}

    #if ($dscResource) {
    #    Write-Debug -Message $dscResource.ParentPath
    #    $invokePath = Join-Path -Path $dscResource.ParentPath -ChildPath 'Invoke.ps1'
    #    Write-Debug -Message "Calling: $invokePath"
    #    if (Test-Path -Path $invokePath) {
    #        #& $invokePath -x $Options
    #        . $InvokePath $options
    #        Invoke-POSHResource $options
    #    } else {
    #        Write-Error -Message "Could not find 'Invoke.ps1' in DSC module: $($dscResource.ParentPath)"
    #    }
    #} else {
    #    throw "Could not find the required DSC resource for type: $Module`:$Resource"
    #}
}