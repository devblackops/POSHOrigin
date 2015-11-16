function _WaitForGuestCustomization {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm
    )
       
    $timeout = 15

    # Wait until VM has started
	Write-Verbose -Message  'Waiting for VM to start...'
    $sw = [diagnostics.stopwatch]::StartNew()
    while ($sw.elapsed.minutes -lt $timeout){
	    $vmEvents = Get-VIEvent -Entity $vm -Verbose:$false 
		$startedEvent = $vmEvents | Where-Object { $_.GetType().Name -eq "VMStartingEvent" }
 
		if ($startedEvent) {
		    break
        }
		else {
		    Start-Sleep -Seconds 5
        }	
    }
    $sw.stop()
    $sw.reset()
 
	# Wait until customization process has started	
	Write-Verbose -Message 'Waiting for customization to start...'
    $sw.start()
    while ($sw.elapsed.minutes -lt $timeout){
	    $vmEvents = Get-VIEvent -Entity $vm -Verbose:$false 
		$startedEvent = $vmEvents | Where-Object { $_.GetType().Name -eq "CustomizationStartedEvent" }
 
		if ($startedEvent) {
		    break	
        }
		else 	 {
		    Start-Sleep -Seconds 5
        }
    }
    $sw.stop()
    $sw.reset()
 
	# wait until customization process has completed or failed
	Write-Verbose -Message 'Waiting for customization to finish...'
    $sw.start()
    while ($sw.elapsed.minutes -lt $timeout){
	    $vmEvents = Get-VIEvent -Entity $vm -Verbose:$false
		$succeedEvent = $vmEvents | Where-Object { $_.GetType().Name -eq "CustomizationSucceeded" }
		$failEvent = $vmEvents | Where-Object { $_.GetType().Name -eq "CustomizationFailed" }
 
		if ($failEvent) {
		    Write-Error -Message 'Customization failed!'
			return $False
        }
 
		if($succeedEvent) {
		    Write-Verbose -Message 'Customization succeeded'
			return $True
        }
 
        Start-Sleep -Seconds 5			
    }
        
    # Wait 5 minutes to allow VM to come up fully
    Write-Verbose -Message 'Waiting 3 minutes...'
    Start-Sleep -Seconds 180
}