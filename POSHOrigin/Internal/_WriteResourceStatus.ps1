
function _WriteResourceStatus {
    [cmdletbinding()]
    param (
        [string]$Resource,

        [string]$Name,

        #[ValidateSet('Test', 'Get', 'Set')]
        [string]$Stage,

        [switch]$Inner,

        [switch]$Complete,

        [string]$Message
    )

    if ($VerbosePreference -eq 'Continue') {
        if (-not $PSBoundParameters.ContainsKey('Inner')) {
            switch ($Stage) {
                'Resource' {
                    #Write-Host -Object "Resource "  -ForegroundColor Cyan -NoNewLine
                    Write-Host -Object "`n[$Resource]" -ForegroundColor Magenta -NoNewLine
                    Write-Host -Object $Name -ForegroundColor Green
                }
                'Test' {
                    Write-Host -Object "  Testing:"  -ForegroundColor Cyan
                    #Write-Host -Object "[$Resource]" -ForegroundColor Magenta -NoNewLine
                    #Write-Host -Object $Name -ForegroundColor Green
                }
                'Get' {
                    Write-Host -Object "  Getting:"  -ForegroundColor Cyan
                }
                'Set' {
                    Write-Host -Object "  Setting:"  -ForegroundColor Cyan
                }
            }
            #Write-Host -Object "[$Resource]" -ForegroundColor Magenta -NoNewLine
            #Write-Host -Object $Name -ForegroundColor Green
        } else {
            if (-Not $PSBoundParameters.ContainsKey('Complete')) {
                # If the message has failure or warning keywors, hightlight the message in red/yellow
                $failureKeywords = @('Mismatch', 'Fail', 'Failure', 'Error', 'Fatal')
                $warningKeywords = @('Warning', 'Warn')
                if (Select-String -InputObject $Message -Pattern $failureKeywords) {
                    #Write-Host -Object "    - $Message" -ForegroundColor Red
                    $color = 'Red'
                } elseIf (Select-String -InputObject $Message -Pattern $warningKeywords) {
                    #Write-Host -Object "    - $Message" -ForegroundColor Yellow
                    $color = 'Yellow'
                } else {
                    #Write-Host -Object "    - $Message" -ForegroundColor Green
                    $color = 'Green'
                }
                Write-Host -Object "    $Message" -ForegroundColor $color
            } else {
                # Get the true/false and time result
                $r = ($Message -split ' ')[0].Trim()
                $time = ($message -split 'in')[1].Trim()
                Write-Host -Object "  Tested: " -ForegroundColor Cyan -NoNewline
                if ($r -eq 'True') {
                    Write-Host -Object "[$r]" -ForegroundColor Green -NoNewline
                    Write-Host -Object " in " -ForegroundColor Cyan -NoNewline
                    Write-Host -Object "$time No changes needed." -ForegroundColor Green
                } else {
                    Write-Host -Object "[$r]" -ForegroundColor Red -NoNewline
                    Write-Host -Object " in " -ForegroundColor Cyan -NoNewline
                    Write-Host -Object "$time" -ForegroundColor Green
                }
                
            }
        }
    }
}
