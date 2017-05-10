function Invoke-POSHOriginNEW {
    <#
        .SYNOPSIS
            Invokes a POSHOrigin configuration directly by calling Invoke-DscResource.

            ** THIS IS AN EXPERIMENTAL CMDLET AND MAY BE SIGNIFICANTLY MODIFIED IN FUTURE VERSIONS **
        .DESCRIPTION
            Invokes a POSHOrigin configuration directly by calling Invoke-DscResource. The custom object(s) passed into this function will be
            translated into a hashtable suitable for Invoke-DscResource.

            ** THIS IS AN EXPERIMENTAL CMDLET AND MAY BE SIGNIFICANTLY MODIFIED IN FUTURE VERSIONS **
        .PARAMETER InputObject
            One or more custom objects containing the required options for the DSC resource to be provisioned.
        .PARAMETER PrettyPrint
            Parse the verbose output and display in an easier to ready format.
        .PARAMETER WhatIf
            Only execute the TEST functionality of DSC.

            NO RESOURCES WILL BE MODIFIED.
        .PARAMETER Confirm
            Prompts you for confirmation before running the cmdlet.
        .PARAMETER PassThru
            Return the result of the DSC run.
        .EXAMPLE
            Compiles and invokes a POSHOrigin configuration. Infrastructure resources defined in $myConfig will be tested for compliance and as
            necessary created, deleted, or modified.

            Invoke-POSHOriginNEW -Resource $myConfig -Verbose
        .EXAMPLE
            Compiles and tests a POSHOrigin configuration. This will only test the DSC resources for compliance.
            NO RESOURCES WILL BE CREATED, DELETED, OR MODIFIED

            Invoke-POSHOrigin -Resource $myConfig -Verbose -WhatIf
        .EXAMPLE
            Pass the options from the POSHOrigin resource directly to Invoke-DscResource.

            $myConfig | Invoke-POSHOriginNEW -NoTranslate -Verbose
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'POSHOrigin.Resource' })]
        [Alias('Resource')]
        [psobject[]]$InputObject,

        [switch]$PrettyPrint,

        [switch]$WhatIf,

        [switch]$PassThru
    )

    begin {

        $PrettyPrint = $PSBoundParameters.ContainsKey('PrettyPrint')

        # Temporarily disable the PowerShell progress bar
        $oldProgPref = $global:ProgressPreference
        $global:ProgressPreference = 'SilentlyContinue'

        # Start stopwatch
        $sw = [diagnostics.stopwatch]::StartNew()

        $results = @()

        # Used to track DSC resources that have been executed.
        # We'll use this so any dependent resources will only execute
        # if all of their dependencies have.
        # NOTE
        # This doesn't validate that the dependent service is in the desired state. Only that the "Set" function was executed
        $executedResources = @()

        function Invoke-DscResourcePrettyPrint {
            [cmdletbinding()]
            param(
                [string]$ResourceName,

                [string]$Method,

                [hashtable]$params
            )

            $result = $null
            if ($PrettyPrint) {
                Invoke-DscResource -Method $Method @params -OutVariable result 4>&1 | _ConvertDscVerboseOutput | foreach {
                    if (($_.message -ne [string]::Empty) -and ($_.State -ne 'End')) {
                        _WriteResourceStatus -Resource $_.resource -Name $ResourceName -Inner -Message $_.message
                    }
                    if ($_.State -eq 'End' -and $_.Stage -eq 'test') {
                        _WriteResourceStatus -Resource $_.resource -Name $ResourceName -Inner -Message $_.message -Complete
                    }
                }
            } else {
                Invoke-DscResource -Method $Method @params -OutVariable result
            }

            return $result
        }
    }

    process {

        foreach ($item in $InputObject) {

            $result = "" | Select Resource, InDesiredState

            # Derive the resource type and module from the resource properties
            # and try to find the DSC resource
            $module = $item.Resource.Split(':')[0]
            $resource = $item.Resource.Split(':')[1]
            $dscResource = _GetDscResource -module $module -Resource $resource

            if ($dscResource) {

                # Construct resource parameters
                if ($null -eq $item.Options.Ensure) {
                    $item.Options | Add-Member -Type NoteProperty -Name 'Ensure' -Value 'Present'
                }

                # Our params and hash to be splatted to Invoke-DscResource
                $params = @{
                    Name = $dscResource.Name
                    ModuleName = @{
                        ModuleName = $dscResource.ModuleName
                        ModuleVersion = $dscResource.Version
                    }
                    Property = ($item | _ConvertToDscResourceHash -DscResource $dscResource)
                    Verbose = $VerbosePreference
                }

                Write-Debug ($params.Property | Format-List -Property * | Out-String)

                if ($PSBoundParameters.ContainsKey('WhatIf')) {
                    # Just test the resource
                    _WriteResourceStatus -Resource $dscResource.Name -Name $item.Name -Stage Test
                    $testResult = Invoke-DscResourcePrettyPrint -Method Test -params $params

                    if ($PSBoundParameters.ContainsKey('PassThru')) {
                        $result = "" | Select Resource, InDesiredState
                        _WriteResourceStatus -Resource $dscResource.Name -Name $item.Name -Stage Get

                        $getResult = Invoke-DscResourcePrettyPrint -Method Get -Params $params

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
                        _WriteResourceStatus -Resource $dscResource.Name -Name $item.Name -Stage Test

                        $testResult = Invoke-DscResourcePrettyPrint -Method Test -params $params

                        #write-verbose ($testResult | fl * | out-string)

                        if (-Not $testResult.InDesiredState) {
                            _WriteResourceStatus -Resource $dscResource.Name -Name $item.Name -Stage Set
                            try {
                                $setResult = Invoke-DscResourcePrettyPrint -Method Set -params $params
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
                        _WriteResourceStatus -Resource $dscResource.Name -Name $item.Name -Stage Test

                        $testResult = Invoke-DscResourcePrettyPrint -Method Test -Params $params

                        _WriteResourceStatus -Resource $dscResource.Name -Name $item.Name -Stage Get
                        $getResult = Invoke-DscResourcePrettyPrint -Method Get -Params $params

                        $result.Resource = $getResult
                        $result.InDesiredState = $testResult.InDesiredState
                        $results += $result
                    }
                }
            } else {
                Write-Error -Message "Unable to find DSC resource: $($item.Resource)"
            }
            Write-Host -Object "`n"
        }
    }

    end {
        # Reset the progress bar preference
        $global:ProgressPreference = $oldProgPref

        if ($PSBoundParameters.ContainsKey('PassThru')) {
            $results
        }

        # Stop stopwatch
        Write-Verbose -Message "Command finished in $($sw.Elapsed.TotalSeconds) seconds"
        $sw.stop()
    }
}
