
function New-POSHOriginResourceFromModule {
    param(
        [parameter(mandatory, position = 0)]
        $Name,

        [parameter(mandatory, position = 1)]
        [hashtable]$Options
    )

    if ($Options.ContainsKey('Source')) {
        if ([System.IO.Path]::IsPathRooted($Options.source)) {
            $path = $Options.source
        } else {
            $here = $MyInvocation.PSScriptRoot
            $path = Join-Path -Path $here -ChildPath $Options.Source -Resolve
        }

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
                    # Are we trying to pass extra items to module?
                    # If so, we just want to run the module entry point script
                    # and not all the files in the module
                    $folderName = Split-Path -Path $path -Leaf
                    if ($modParams.Count -gt 0) {
                        $callEntryPoint = $true
                        $folderName = Split-Path -Path $path -Leaf
                        $modFiles = Get-Item -Path (Join-Path -Path $path -ChildPath "$folderName.ps1")
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


                ##$modFile = $modFile.FullName

                ##if ($modFile) {

                    
                    

                ##     Is this a smart module? If so just process the entry script
                ##     and not all the files in the module
                ##    if ($smartMod) {
                        
                ##    } else {
                ##        $script:modulesToProcess.Add($path, $name)
                ##        $files = Get-ChildItem -Path $path -File -Filter '*.ps1' -Recurse
                ##        Write-Verbose -Message "Module: $Name - Items: $($files.Count) - Path: $modFile"
                ##        $files | ForEach-Object {
                ##            $configdata += @(. $_.FullName @modParams)
                ##        }
                ##    }
                ##    return $configData
                ##} else {
                ##    throw ($msgs.nporff_module_not_found -f $Path)
                ##}
            } else {
                throw ($msgs.nporff_module_not_found -f $path)
            }
        } else {
            Write-Warning -Message "Module $Name($path) has already been referenced by another configuration and will not be processed again"
        }
    } else {
        throw $msgs.nporff_no_source
    }
}