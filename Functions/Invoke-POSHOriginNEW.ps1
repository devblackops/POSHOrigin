function Invoke-POSHOriginNEW {
    [cmdletbinding()]
    param(
        [parameter(Mandatory,ValueFromPipeline)]
        [psobject[]]$Resource,

        [switch]$NoTranslate,

        [switch]$WhatIf,

        [switch]$PassThru
    )

    begin {

        # Start stopwatch
        $sw = [diagnostics.stopwatch]::StartNew()

        $results = @()

        # Used to track DSC resources that have been executed.
        # We'll use this so any dependent resources will only execute
        # if all of their dependencies have.
        # NOTE
        # This doesn't validate that the dependent service is in the desired state. Only that the "Set" function was executed
        $executedResources = @()

        if ($PSBoundParameters.ContainsKey('NoTranslate')) {
            Write-Verbose -Message "NoTranslate specified. No property translation will be attempted"
        }

        function Write-ResourceStatus {
            param (
                [string]$Resource,
                [string]$Name,
                [ValidateSet('Test', 'Get', 'Set')]
                [string]$State
            )
            $cmd = {
                switch ($State) {
                    'Test' {
                        Write-Host -Object "Testing resource "  -ForegroundColor Cyan -NoNewLine
                    }
                    'Get' {
                        Write-Host -Object "Getting resource "  -ForegroundColor Cyan -NoNewLine
                    }
                    'Set' {
                        Write-Host -Object "Setting resource "  -ForegroundColor Cyan -NoNewLine
                    }
                }
                Write-Host -Object "[$Resource" -ForegroundColor Magenta -NoNewLine
                Write-Host -Object "[$Name]" -ForegroundColor Green -NoNewLine
                Write-Host -Object "]" -ForegroundColor Magenta
            }

            Invoke-Command -ScriptBlock $cmd
        }
    }

    process {
        foreach ($item in $Resource) {
            #Write-Host -Object "`n"

            $result = "" | Select Resource, InDesiredState

            # Derive the resource type and module from the resource properties
            # and try to find the DSC resource
            $module = $item.Resource.Split(':')[0]
            $resource = $item.Resource.Split(':')[1]
            $dscResource = Get-DscResource -Name $resource -Module $module -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (-Not $dscResource) {
                $dscResource = Get-DscResource -Name $resource -Module "POSHOrigin_$module" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }
            if (-Not $dscResource) {
                $dscResource = Get-DscResource -Name $resource -Module 'POSHOrigin' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }

            if ($dscResource) {

                # Construct resource parameters
                if ($null -eq $item.Options.Ensure) {
                    $item.Options | Add-Member -Type NoteProperty -Name 'Ensure' -Value 'Present'
                }

                # Our params and hash to be splatted to Invoke-DscResource
                $params = @{}
                $hash = @{}

                # Test for 'Invoke.ps1' script in DSC resource module and optionally use it to translate our options into what the
                # DSC resource expects.
                # If there is no 'Invoke.ps1' script or we specified '-NoTranslate' then pass the resource object directly to the DSC resource
                # without any translation. This requires that the correct property names are specificed in the configurations file
                # as they will be passed directly to Invoke-DscResource.
                $invokePath = Join-Path -Path $dscResource.ParentPath -ChildPath 'Invoke.ps1'
                if (Test-Path -Path $invokePath) {
                    if (-Not $PSBoundParameters.ContainsKey('NoTranslate')) {
                        # Use the 'Invoke.ps1' script to translate our options into what the DSC resource expects.
                        Write-Verbose -Message "Calling $invokePath to translate properties"
                        $hash = & $invokePath -Options $item -Direct:$true
                    } else {
                        # We are intentially not using the 'Invoke.ps1' script and instead directly passing the object on
                        $propNames = $item.options | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object {$_ -ne 'DependsOn'}
                        $propNames | ForEach-Object {
                            $hash.Add($_, $item.Options.$_)
                        }
                        # We have to stip out any properties from the POSHOrigin resource object that the DSC resource does not expect
                        $dscResourceProperties = $dscResource.Properties | Select-Object -ExpandProperty Name
                        $hashProperties = $hash.GetEnumerator() | Select-Object -ExpandProperty Name
                        foreach ($hashProperty in $hashProperties) {
                            if ($hashProperty -inotin $dscResourceProperties) {
                                $hash.remove($hashProperty)
                            }
                        }
                    }
                } else {
                    #throw "$invokePath not found in DSC module so no property translation could be made. Try using the -NoTranslate switch instead."
                    # There is no 'Invoke.ps1' script we we'll just pass on the properties directly to the DSC resource
                    # without any translation
                    $propNames = $item.options | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
                    $propNames | ForEach-Object {
                        $hash.Add($_, $item.Options.$_)
                    }
                    # We have to stip out any properties from the POSHOrigin resource object that the DSC resource does not expect
                    $dscResourceProperties = $dscResource.Properties | Select-Object -ExpandProperty Name
                    $hashProperties = $hash.GetEnumerator() | Select-Object -ExpandProperty Name
                    foreach ($hashProperty in $hashProperties) {
                        if ($hashProperty -inotin $dscResourceProperties) {
                            $hash.remove($hashProperty)
                        }
                    }
                }

                $params = @{
                    Name = $dscResource.Name
                    ModuleName = $dscResource.ModuleName
                    Property = $hash
                }

                #Write-Host ($params.Property | format-list * | Out-String)
                #Write-Host $hash.GuestCredentials.Username
                
                if ($PSBoundParameters.ContainsKey('WhatIf')) {
                    # Just test the resource
                    Write-ResourceStatus -Resource $dscResource.Name -Name $item.Name -State Test
                    $testResult = $null
                    $testResult = Invoke-DscResource -Method Test @params -Verbose:$VerbosePreference

                    if ($PSBoundParameters.ContainsKey('PassThru')) {
                        $result = "" | Select Resource, InDesiredState
                        Write-ResourceStatus -Resource $dscResource.Name -Name $item.Name -State Get

                        $getResult = $null
                        $getResult = Invoke-DscResource -Method Get @params -Verbose:$VerbosePreference
                        $result.Resource = $getResult
                        $result.InDesiredState = $testResult.InDesiredState
                        $results += $result
                    }
                } else {

                    # Test if this resource has any dependencies and only execute if those have been met.
                    $continue = $true
                    $dependenciesExist = @(($item.DependsOn).Count -gt 0)
                    if ($dependenciesExist) {
                        if ($dependency -inotin $executedResources.Keys) {
                            $continue = $false
                        }
                    } else {
                        $continue = $true
                    }

                    # All dependencies met?
                    if ($continue) {
                        # Test and invoke the resource
                        $testResult = $null
                        Write-ResourceStatus -Resource $dscResource.Name -Name $item.Name -State Test
                        $testResult = Invoke-DscResource -Method Test @params -Verbose:$VerbosePreference -InformationAction $InformationPreference
                        if (-Not $testResult.InDesiredState) {
                            Write-ResourceStatus -Resource $dscResource.Name -Name $item.Name -State Set
                            try {
                                $setResult = Invoke-DscResource -Method Set @params -Verbose:$VerbosePreference -InformationAction $InformationPreference
                            } catch {
                                Write-Error -Message 'There was a problem setting the resource'
                                Write-Error -Message "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
                                write-Error $_
                            }
                        }
                        # Track the resource as 'executed' for dependent resources
                        $executedResources += $item.FullName
                    } else {
                        Write-Error -Message "Dependencies have not been met for resource $($item.FullName). This resource will not be invoked."
                    }

                    if ($PSBoundParameters.ContainsKey('PassThru')) {
                        Write-ResourceStatus -Resource $dscResource.Name -Name $item.Name -State Test
                        $testResult = $null
                        $testResult = Invoke-DscResource -Method Test @params -Verbose:$VerbosePreference -InformationAction $InformationPreference
                        
                        Write-ResourceStatus -Resource $dscResource.Name -Name $item.Name -State Get
                        $getResult = $null
                        $getResult = Invoke-DscResource -Method Get @params -Verbose:$VerbosePreference -InformationAction $InformationPreference

                        $result.Resource = $getResult
                        $result.InDesiredState = $testResult.InDesiredState
                        $results += $result
                    }
                }
            } else {
                Write-Error -Message "Unable to find DSC resource: $($item.Resource)"
            }
        }
    }

    end {
        if ($PSBoundParameters.ContainsKey('PassThru')) {
            $results
        }

        # Stop stopwatch
        Write-Verbose -Message "`nCommand finished in $($sw.elapsed.seconds) seconds"
        $sw.stop()
    }
}
