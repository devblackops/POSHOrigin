
function _ConvertDSCVerboseOutput {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [string[]]$InputObject
    )

    begin {
        $state = [string]::Empty
        $stage = [string]::Empty
        $resource = [string]::Empty
        $enteringStage = $false
        $resourceName = [string]::Empty
        $newSection = $false
    }

    process {

        # Try and extract the information we want from the line
        foreach ($line in $InputObject) {
            $enteringStage = $false
            #Write-Verbose $line            
            $line = $line | Select-String -Pattern '^.*?:'
            $msg = $null

            if ($line -split ']: ') {
                $machine = ($line -split ']: ')[0].TrimStart(1,'[')
            }

            $message = [string]::Empty

            # Pull out the current stage (get,test,set), state (start, end), and resource name
            if ($line -match 'LCM:\s\s\[\s') {
                if (($line -split '(LCM:\s\s\[)(\s)(.*?\s)(\s*.*?\s)')[3]) {
                    $state = ($line -split '(LCM:\s\s\[)(\s)(.*?\s)(\s*.*?\s)')[3].Trim()
                }
                if (($line -split '(LCM:\s\s\[)(\s)(.*?\s)(\s*.*?\s)')[4]) {
                    $stage = ($line -split '(LCM:\s\s\[)(\s)(.*?\s)(\s*.*?\s)')[4].Trim()
                    $enteringStage = $true
                }

                # The DSC resource name and unique instance name
                if ($line -match '\[\[') {
                    $resource = ($line -split '\[\[')[1].Split(']')[0]
                    $resourceName = ($line -split '\[\[')[1].Split(']')[1]
                }
            }

            if ($line -match '\[\[.*\].*\]') {
                $message = ($line -split '\[\[.*\].*\]')[1].Trim()
            } else {
                if ($line -notmatch '[ Start  Compare ]') {
                    $message = ($line -split 'LCM:\s\s\[\sEnd\s\s\s\sSet\s\s\s\s\s\s]')[1].Trim()
                }
            }

            $msg = [pscustomobject]@{
                Machine = $machine
                State = $state
                Stage = $stage
                EnteringStage = $enteringStage
                Resource = $resource
                ResourceName = $resourceName
                Message = $message
            }
            $msg
            #Write-Verbose ($msg | ft * | out-string)
        }
    }

    end {}
}
