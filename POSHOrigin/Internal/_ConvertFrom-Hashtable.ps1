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
        $output = @()
    }

    process {
        if ($recurse) {
            $keys = $hashtable.Keys | ForEach-Object { $_ }
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
            $output += @(New-Object -TypeName PSCustomObject -Property $hashtable)
        } else {
            New-Object -TypeName PSCustomObject -Property $hashtable -Strict
        }
    }

    end {
        if($combine -and $output.Count -gt 1) {
            $output | Join-Object
        } else {
            $output
        }
    }
}