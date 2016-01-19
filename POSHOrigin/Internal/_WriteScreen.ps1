
function _WriteScreen {
    #wraps the Write-Host cmdlet to control if the output is written to screen from one place
    param(
        #Write-Host parameters
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [Object] $Object,
        [Switch] $NoNewline,
        [Object] $Separator,
        [String] $OutputType = 'Standard'
    )

    begin {

        if ($PSBoundParameters.ContainsKey('OutputType')) { $PSBoundParameters.Remove('OutputType') | Out-Null}

        if ($OutputType -ne 'Standard') {
            #create the key first to make it work in strict mode
            if (-not $PSBoundParameters.ContainsKey('ForegroundColor')) {
                $PSBoundParameters.Add('ForegroundColor', $null)
            }

            $PSBoundParameters.ForegroundColor = [MsgType]::$OutputType
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Host', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}