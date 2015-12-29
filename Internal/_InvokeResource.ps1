#function _InvokeResource {
#    [cmdletbinding()]
#    param(
#        [parameter(mandatory)]
#        [psobject]$Options
#    )

#    # Derive the resource type and module from the options passed in
#    # and try to find the DSC resource
#    $module = $_.Resource.Split(':')[0]
#    $resource = $_.Resource.Split(':')[1]
#    $dscResource = Get-DscResource -Name $resource -Module $module -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
#    if (-Not $dscResource) {
#        $dscResource = Get-DscResource -Name $resource -Module "POSHOrigin_$module" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
#    }
#    if (-Not $dscResource) {
#        $dscResource = Get-DscResource -Name $resource -Module 'POSHOrigin' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
#    }

#    # Execute the 'Invoke.ps1' script inside the module
#    # Invoke.ps1 will translate the resource options into a DSC resource
#    if ($dscResource) {

#        $type = $module + "_" + $resource
#        $resourceFile = "$moduleRoot\Internal\resources\$Type.ps1"
#        if (Test-Path -Path $resourceFile) {
#            & $resourceFile -x $_
#        } else {
#            Write-Error -Message "Unknown resource type [$Type]"
#        }
        
#        #& $cmd

#        #$type = $module + '_' + $resource
#        #$resourceFile = "$moduleRoot\Internal\resources\$type.ps1"
#        #if (Test-Path -Path $resourceFile) {
#        #   . $resourceFile -x $Options
#        #} else {
#        #    Write-Error -Message "Unknown resource type [$resourceFile]"
#        #}


        
#        #$type = $module + "_" + $resource
#        #$resourceFile = "$moduleRoot\Internal\resources\$Type.ps1"
#        #$invokePath = Join-Path -Path $dscResource.ParentPath -ChildPath 'Invoke.ps1'
#        #if (Test-Path -Path $invokePath) {
#        #    Write-Verbose -Message "Calling: $invokePath"
#        #    # Maybe try returning this as a string and using invoke-express?
#        #    . $invokePath -Options $Options -Direct:$false
#        #} else {
#        #    Write-Error -Message "Unknown resource type [$invokePath]"
#        #}

#        #$invokePath = "$($dscResource.ParentPath)\Invoke.ps1"
#        #if (Test-Path -Path $invokePath) {
#        #    . $invokePath -Options $options
#        #} else {
#        #    Write-Error -Message "Unable to find Invoke.ps1 inside module: $($dscResource.ParentPath)"
#        #}
        
#    } else {
#        Write-Error -Message "Unable to resolve DSC module for resource [$module`:$resource]"
#    }

    

#    # Try to find the DSC resource
#    #$dscResource = Get-DscResource -Name $Resource -Module $Module -ErrorAction SilentlyContinue
#    #if (-Not $dscResource) {
#    #    $dscResource = Get-DscResource -Name $Resource -Module "POSHOrigin_$Module" -ErrorAction SilentlyContinue
#    #}

#    #if ($dscResource) {
#    #    Write-Debug -Message $dscResource.ParentPath
#    #    $invokePath = Join-Path -Path $dscResource.ParentPath -ChildPath 'Invoke.ps1'
#    #    Write-Debug -Message "Calling: $invokePath"
#    #    if (Test-Path -Path $invokePath) {
#    #        #& $invokePath -x $Options
#    #        . $InvokePath $options
#    #        Invoke-POSHResource $options
#    #    } else {
#    #        Write-Error -Message "Could not find 'Invoke.ps1' in DSC module: $($dscResource.ParentPath)"
#    #    }
#    #} else {
#    #    throw "Could not find the required DSC resource for type: $Module`:$Resource"
#    #}
#}