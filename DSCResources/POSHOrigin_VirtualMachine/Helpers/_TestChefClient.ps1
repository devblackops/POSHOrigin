function _TestGuestDisks {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $vm,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    begin {
        Write-Debug -Message '_TestChefClient() starting'
    }

    process {

        $pass = $true

        return $pass
    }

    end {
        Write-Debug -Message '_TestChefClient() ending'
    }
}