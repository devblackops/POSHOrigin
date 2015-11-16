function _WaitForVMTools {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    $toolsTimeout = 20
    $ipTimeout = 20

    # Wait until VM tools is available and we have an IP
    $result = Wait-Tools -Vm $vm -TimeoutSeconds (60 * $toolsTimeout) -verbose:$false
    
    if ($result -ne $null) {
        Write-Verbose -Message 'VM tools started'
        Write-Verbose -Message 'Waiting for VM to become available...'
        $sw = [diagnostics.stopwatch]::StartNew()
        while ($sw.elapsed.minutes -lt $ipTimeout){
            $vmView = $vm | get-view -verbose:$false
            if ($vmView.Guest.IpAddress -and $vmView.Guest.IpAddress -notlike '169.*') {
                $p = Invoke-Command -ComputerName $vmView.Guest.IpAddress -Credential $Credential -ScriptBlock { Get-Process } -ErrorAction SilentlyContinue
                if ($null -ne $p) {
                    break
                }
            }
            Start-Sleep -Seconds 5
        }
        return $true
    } else {
        Write-Error -Message 'VM tools did not start withing the alloted time'
    }
    return $false
}