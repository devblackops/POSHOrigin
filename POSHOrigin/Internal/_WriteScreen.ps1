
function _WriteScreen {
    #wraps the Write-Verbose cmdlet to control colors
    [cmdletbinding()]
    param(
        [Object]$Object,
        [Switch]$NoNewline,
        #[Object]$Separator,
        #[Switch]$Quiet = ($VerbosePreference -eq 'SilentlyContinue'),
        [Switch]$Quiet = $false,
        [ValidateSet('Standard', 'File', 'Module', 'Resource', 'ResourceDetail')]
        [String]$OutputType = 'Standard'
    )

    begin {

        # If we're not -Verbose, do nothing
        if ($Quiet) { return }

        # Make the bound parameters compatible with Write-Host
        if ($PSBoundParameters.ContainsKey('Quiet')) { $PSBoundParameters.Remove('Quiet') | Out-Null }
        if ($PSBoundParameters.ContainsKey('OutputType')) { $PSBoundParameters.Remove('OutputType') | Out-Null}

        if ($OutputType -ne 'Standard') {
            # Create the key first to make it work in strict mode
            if (-not $PSBoundParameters.ContainsKey('ForegroundColor')) {
                $PSBoundParameters.Add('ForegroundColor', $null)
            }

            $PSBoundParameters.ForegroundColor = [MsgType]::$OutputType
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Host', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters}
            #$scriptCmd = { & $wrappedCmd -Message $Object -Verbose } 
            #$scriptCmd = { & $wrappedCmd -Object $Object -ForegroundColor $PSBoundParameters.ForegroundColor }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        if ($Quiet) { return }

        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        if ($Quiet) { return }

        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}