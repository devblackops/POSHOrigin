
function New-POSHOriginResourceFromModule {
    <#
    .SYNOPSIS
        Returns POSHOrigin resource(s) defined in a given folder or git repository.
    .DESCRIPTION
        Returns POSHOrigin resource(s) defined in a given folder or git repository. If a .ps1 script with the same name as the module folder is
        found, only that script will be invoked. That script (the module entry point) is responsible for containing logic to process and return
        any needed POSHOrigin resources defined in the module. If additional options are specified for the module, those options will be passed
        to the module entry point script.
    .PARAMETER Name
        The name of the POSHOrigin module
    .PARAMETER Options
        Hashtable of options to pass to POSHOrigin module.

        At a minimum, a property called 'Source' must be specified. The source property can point to a local file/folder, a file/folder on an
        SMB share, or a git URL in the format of 'git://hostname.mydomain.tld/username/repo.git'. If pointing to a git URL, 'git.exe' must be
        available in the user's path.        
    .EXAMPLE
        Returns all POSHOrigin resources defined in the module 'compute_xl_gold' at location '.\modules\compute\xl_gold'. The POSHOrigin module
        contains a script with the same name as the folder 'xl_gold.ps1' which is responsible for returning the actual POSHOrigin resources for
        the module.
        
        The alias 'module' is usually used instead of the full cmdlet name New-POSHOriginResourceFromModule.
        
        module 'compute_xl_gold' @{
            source = '.\modules\compute\xl_gold'
            name = "server$_"
        }
    .EXAMPLE
        Returns all POSHOrigin resources defined in the module 'gitmodule' at location 'git://github.com/<username>/<module>.git'. POSHOrigin
        will clone this repository into a temporary folder and execute the resources contained within. If there is a file at the root of the
        repository with the same name as the repository, that script (the entry point script) will be the only file executed and it will be
        passed any additional parameters specified with the module minus the <Source> property. After executing the resources, the temporary
        folder will be deleted. 

        module 'gitmodule' @{
            source = 'git://github.com/<username>/<module>.git'
            param1 = 'foo'
            param2 = 'bar'
        }
    #>
    param(
        [parameter(mandatory, position = 0)]
        $Name,

        [parameter(mandatory, position = 1)]
        [hashtable]$Options
    )

    if ($Options.ContainsKey('Source')) {

        # Is Source a git url?
        if ($Options.source -match '^git://*') {

            # See if we've all ready downloaded this module as part of this POSHOrigin execution
            # If so, just use the previously downloaded location
            if (-not $script:gitModulesProcessed.ContainsKey($Options.source)) {
                $path = _GetGenericGitRepo -Url $Options.Source
                $script:gitModulesProcessed.Add($Options.source, $path)
            } else {
                $path = $script:gitModulesProcessed[$Options.source]
            }
        } else {
            # Source is a local directory
            if ([System.IO.Path]::IsPathRooted($Options.source)) {
                $path = $Options.source
            } else {
                $here = $MyInvocation.PSScriptRoot
                $path = Join-Path -Path $here -ChildPath $Options.Source -Resolve
            }
        }
        
        if ($Path) {
            if (-Not $script:modulesToProcess.ContainsKey($path)) {
                if (Test-Path -Path $path) {

                    $callEntryPoint = $false
                    $modParams = _CopyObject -DeepCopyObject $Options
                    $modParams.Remove('Source')

                    $modItem = Get-Item -Path $Path
                    $modFiles = @()

                    Write-Verbose -Message "  Module: $Name - Path: $Path"

                    if ($modItem.PSIsContainer) {
                        # We specified a module folder
                        # Are we trying to pass extra items to module or does a script
                        # with the same name as the folder exist?
                        # If so, we just want to run the module entry point script
                        # and not all the files in the module

                        $folderName = Split-Path -Path $path -Leaf
                        $entryPointScript = (Join-Path -Path $path -ChildPath "$folderName.ps1")
                        
                        if (($modParams.Count -gt 0) -or (Test-Path -Path $entryPointScript)) {
                            $callEntryPoint = $true
                            Write-Verbose -Message "    Executing module entry point script [$entryPointScript]"
                            $modFiles = Get-Item -Path $entryPointScript
                        } else {
                            # Run all files in module except the entry point script if it exists
                            Write-Verbose -Message "    Specified module folder. Loading all files within"
                            $modFiles = Get-ChildItem -Path $modItem -File -Filter '*.ps1' -Exclude "$folderName.ps1" -Recurse
                        }
                    } else {
                        # Are we calling the entry point script directly?
                        $folderName = Split-Path -Path $path -Parent
                        if ($modItem.BaseName -eq $folderName) {
                            $callEntryPoint = $true
                        }
                        $modFiles = $modItem
                    }

                    # Execute POSHOrigin files
                    $configdata = @()
                    foreach ($modFile in $modFiles) {
                        if ($callEntryPoint) {
                            # Call entry point script and pass params
                            $configdata += @(. $modFile @modParams)
                        } else {
                            # Call script with no params
                            $configdata += @(. $modFile @modParams)
                        }
                    }
                    return $configData
                } else {
                    throw ($msgs.nporff_module_not_found -f $path)
                }
            } else {
                Write-Warning -Message "Module $Name($path) has already been referenced by another configuration and will not be processed again"
            }
        } else {
            Write-Error -Message "Unable to retrieve module from source [$Source]"
        }        
    } else {
        throw $msgs.nporff_no_source
    }
}
