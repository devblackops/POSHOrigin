function _MergeHashtables {
    <#
    .SYNOPSIS
    Merges two hashtables together and returns the result

    .DESCRIPTION
    When adding two hashes together, an error will be thrown if there are duplicate keys in the table.

    The order in which the hashtables are passed to the function is very important.  So the primary hashtable
    will be the master, and keys that exist here will override the same one in the secondary hashtable.

    The only exception to this is that the system will determine if both keys are another hashtable.  If they are
    then the function is called recursively again to provide the merged tables

    Credit
    Originally taken from the following page: http://jdhitsolutions.com/blog/2013/01/join-powershell-hash-tables
    #>
    [cmdletbinding()]
    Param (
        [hashtable]
        # First hashtable to merge, this will have priority
        $Primary,

        [hashtable]
        # second hashtable to merge
        $Secondary
    )

    # Do not touch the original hashtables
    #$PrimaryClone  = $primary.Clone()
    #$SecondaryClone = $secondary.Clone()
    $primaryClone = _CopyObject -DeepCopyObject $Primary
    $secondaryClone = _CopyObject -DeepCopyObject $Secondary

    # Create an array of types that can be merged.
    # Hashtables and Dictionaries can be merged
    $types = @(
        "Hashtable"
        "Dictionary"
    )

    # Check for any duplicate keys
    $duplicates = $primaryClone.keys | where {$secondaryClone.ContainsKey($_)}

    if ($duplicates) {
        foreach ($key in $duplicates) {

            # If the item is a hashtable then call this function again
            if ($types -contains $primaryClone.$key.gettype().name -and
                $types -contains $secondaryClone.$key.gettype().name) {
                $splat = @{
                    primary = $primaryClone.$key
                    secondary = $secondaryClone.$key
                }
                $primaryClone.$key = _MergeHashtables @splat
            }
                
            <#
            # If the key is an array merge the two items
            if ($PrimaryClone.$key.GetType().Name -eq "Object[]" -and $SecondaryClone.$key.GetType().name -eq "Object[]") {

                $result = @()

                # Because an array can contain many different types, need to be careful how this information is merged
                # This means that the normal additional functions and the Unique parameter of Select will not work properly
                # so iterate around each of the two arrays and add to a result array
                foreach ($arr in @($PrimaryClone.$key, $SecondaryClone.$key)) {

                    # analyse each item in the arr
                    foreach ($item in $arr) {

                        # Switch on the type of the item to determine how to add the information
                        switch ($item.GetType().Name) {
                            "Object[]" {
                                $result += , $item
                            }

                            # If the type is a string make sure that the array does not already
                            # contain the same string
                            "String" {
                                if ($result -notcontains $item) {
                                    $result += $item
                                }
                            }

                            # For everything else add it in
                            default {
                                $result += $item
                            }
                        }
                    }
                }

                # Now assign the result back to the primary array
                $PrimaryClone.$key = $result
            }
            #>

            # Force primary key, so remove secondary conflict
            $secondaryClone.Remove($key)
        }
    }

    # Join the two hash tables and return to the calling function
    return ($primaryClone + $secondaryClone)
}