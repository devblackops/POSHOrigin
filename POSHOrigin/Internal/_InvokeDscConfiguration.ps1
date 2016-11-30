
function _InvokeDscConfiguration {
    [cmdletbinding(DefaultParameterSetName = 'local')]
    param(
        #[ValidateSet('get','set','test')]
        #[string]$Method,

        [parameter(ParameterSetName = 'remote')]
        [string]$ComputerName,

        [parameter(ParameterSetName = 'local')]
        [string]$Path,

        [bool]$PrettyPrint,

        [bool]$TestOnly = $false
    )

    $results = $null

    if ($PSCmdlet.ParameterSetName -eq 'local') {

        if ($TestOnly) {

            # Only test the DSC configuration and optionally PrettyPrint it
            if ($PrettyPrint) {
                $results = Test-DscConfiguration -Path $Path 4>&1 | _ConvertDSCVerboseOutput | foreach {
                    if ($_.EnteringStage -and $_.State -eq 'Start' -and $_.resourceName) {
                        _WriteResourceStatus -Resource $_.resource -Name $_.resourceName -Stage $_.Stage
                    }

                    # The current resource status
                    if (($_.Message -ne [string]::Empty) -and ($_.State -ne 'End')) {
                        _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $_.Message
                    }

                    # The current resource is complete
                    if ($_.Stage -eq 'Test' -and $_.State -eq 'End') {
                        _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $_.Message -Complete
                    }
                }
            } else {
                $results = Test-DscConfiguration -Path $Path
            }
            return $results
        } else {
            # Execute the DSC configuration and optionally PrettyPrint it
            if ($PrettyPrint) {
                $endTestMsg = [string]::empty
                $endSetMsg = [string]::empty
                Start-DscConfiguration -Path $Path -Force -Wait -OutVariable results 4>&1 | _ConvertDSCVerboseOutput | foreach {

                    #Write-Debug ($_ | ft * | out-string)

                    # Display the start of the resource
                    if ($_.Stage -eq 'Resource' -and $_.State -eq 'Start') {
                        _WriteResourceStatus -Resource $_.resource -Name $_.resourceName -Stage $_.Stage
                    }

                    # Display the start of the test/set
                    if (($_.Stage -eq 'Test' -or $_.Stage -eq 'Set') -and $_.State -eq 'Start' -and $_.resourceName -and $_.Message -eq [string]::empty) {
                        if ($endTestMsg -eq [string]::empty) {
                            _WriteResourceStatus -Resource $_.resource -Name $_.resourceName -Stage $_.Stage
                        }
                    }

                    # Grab the ending message of the stage. This includes the time it took to execute that stage
                    if ($_.Stage -eq 'Test' -and $_.State -eq 'End') {
                        $endTestMsg = $_.Message
                    }
                    if ($_.Stage -eq 'Set' -and $_.State -eq 'End') {
                        $endSetMsg = $_.Message
                    }

                    # Display the message for current stage
                    if ($_.EnteringStage -eq $false -and ($_.Message -ne [string]::Empty)) {
                        _WriteResourceStatus -Resource $_.Resource -Name $_.ResourceName -Inner -Message $_.Message
                    }

                    # # Testing the current resource is complete
                    # # Skip this message and continue processing other lines to see if the resource testing true/false.
                    # # For some reason, when using Start-DscConfiguration the verbose message at the end of the test stage doesn't
                    # # state if it is in the desired state or not. For that, we must look for the line saying the Set state was skipped
                    # # or not. DUMB
                    if ($_.Stage -eq 'Set' -and $_.ResourceName) {
                        if ($_.State -eq 'Skip') {
                            $endTestMsg = "True $EndTestMsg"
                            #Write-Debug "Skipping set"
                            #Write-Debug $endTestMsg
                            _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $endTestMsg -Complete
                            $endTestMsg = [string]::Empty
                        } elseIf ($_.State -eq 'Start') {
                            #Write-Debug 'starting set stage'
                            #Write-Debug "endtestmsg: $endTestMsg"
                            if ($endTestMsg -like 'in *') {
                                $endTestMsg = "False $endTestMsg"
                                if ($_.EnteringStage -eq $true) {
                                    _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $endTestMsg -Complete
                                    _WriteResourceStatus -Resource $_.resource -Name $_.resourceName -Stage 'Set'
                                    $endTestMsg = [string]::Empty
                                }
                            }
                        }
                    }
                }
                return $results
            } else {
                $results = Start-DscConfiguration -Path $Path -Force -Wait
                return $results
            }
        }
    } else {

        if ($TestOnly) {
            # Only test the DSC configuration and optionally PrettyPrint it
            if ($PrettyPrint) {
                $results = Test-DscConfiguration -ComputerName $ComputerName 4>&1 | _ConvertDSCVerboseOutput | foreach {
                    if ($_.EnteringStage -and $_.State -eq 'Start' -and $_.resourceName) {
                        _WriteResourceStatus -Resource $_.resource -Name $_.resourceName -Stage $_.Stage
                    }

                    # The current resource status
                    if (($_.Message -ne [string]::Empty) -and ($_.State -ne 'End')) {
                        _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $_.Message
                    }

                    # The current resource is complete
                    if ($_.Stage -eq 'Test' -and $_.State -eq 'End') {
                        _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $_.Message -Complete
                    }
                }
            } else {
                $results = Test-DscConfiguration -ComputerName $ComputerName
            }
            return $results
        } else {
            # At some point we may want to support a pool of provisioning servers and come up with
            # logic to pick an available one and publish/start the configuration on a provisiong server
            # not currently executing a configuration            
            if ($PrettyPrint) {
                Start-DscConfiguration -ComputerName $ComputerName -Confirm:$false -Force -Wait 4>&1 | _ConvertDSCVerboseOutput foreach {
                    # We are begining to process a new resource
                    if ($_.Stage -eq 'Resource' -and $_.State -eq 'Start') {
                        _WriteResourceStatus -Resource $_.resource -Name $_.resourceName -Stage Test
                    }

                    # The current resource status
                    if (($_.Message -ne [string]::Empty) -and ($_.State -ne 'End')) {
                        _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $_.Message
                    }

                    # The current resource is complete
                    if ($_.Stage -eq 'Test' -and $_.State -eq 'End') {
                        _WriteResourceStatus -Resource $_.Resource -Name $ResourceName -Inner -Message $_.Message -Complete
                    }
                }
            } else {
                Start-DscConfiguration -ComputerName $ComputerName -Confirm:$false -Force -Wait
            }
        }
    }
}
