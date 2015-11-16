function _ConvertFrom-Hashtable {
    [OutputType([system.object[]])]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [HashTable]$hashtable = @{},

        [switch]$combine,

        [switch]$recurse
    )

    begin {
        #Write-Debug -Message '_ConvertFrom-Hashtable(): beginning'
        $output = @()
    }

    process {
        if ($recurse) {
            $keys = $hashtable.Keys | ForEach-Object { $_ }
            #Write-Verbose "Recursing $($Keys.Count) keys"
            foreach ($key in $keys) {
                if ($hashtable.$key -is [HashTable]) {
                    $hashtable.$key = _ConvertFrom-Hashtable $hashtable.$key -Recurse -Combine:$combine
                }
                if ($hashTable.$key -is [array]) {
                    $x = @()
                    foreach ($item in $hashTable.$key) {
                        if ($item -is [HashTable]) {
                            $item = _ConvertFrom-Hashtable $item -Recurse -Combine:$combine
                            $x += $item
                        } else {
                            $x += $item
                        }
                    }
                    $hashTable.$key = $x
                }
            }
        }

        if($combine) {
            $output += @(New-Object -TypeName PSObject -Property $hashtable)
            #Write-Verbose "Combining Output = $($Output.Count) so far"
        } else {
            New-Object -TypeName PSObject -Property $hashtable -Strict
        }
    }

    end {
        if($combine -and $output.Count -gt 1) {
            #Write-Verbose "Combining $($Output.Count) cached outputs"
            $output | Join-Object
        } else {
            $output
        }
        #Write-Debug -Message '_ConvertFrom-Hashtable(): ending'
    }
}