function _LoadConfigNEW {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Path,

        [switch]$Recurse
    )

    $credentialCache = @{}

    $configs = @()
    $item = Get-Item -Path $Path
    if ($item.PSIsContainer) {
        $files = Get-ChildItem -Path $item -Filter '*.ps1' -Recurse:$Recurse
    } else {
        $files = $item
    }

    Write-Verbose -Message "$($Path): $($files.Count)"
    if ($files.Count -gt 0) {
        foreach ($file in $files) {
            $filePath = $file.FullName
            Write-Verbose -Message "Processing file [ $filePath ]"
            $config = @(. $filePath)

            # The file could have returned multiple resources
            # let's loop through them all and process them
            foreach ($resource in $config) {
                #$copy = _CopyObject -DeepCopyObject $resource
                Write-Verbose -Message "Processing resource [ $($resource.Name) ]"
                Write-Debug -Message "Resource options: $($resource.Options | Format-List | Out-String)"

                # Inspect the secrets
                $secrets = $resource.options.secrets
                foreach ($key in $secrets.keys) {
                    Write-Debug -Message "Processing secret $($resource.Name).$key"
                    $secret = $secrets.$key
                    $resolver = $secret.resolver
                    $options = $secret.options

                    #if ($key -eq 'guest') {
                    #    if ($options.ContainsKey('username')) {
                    #        # if the guest credential doesn't have a domain or computer name
                    #        # as part of the username, make sure to add it
                    #        if ($options.username -notcontains '\') {
                    #            $options.username = "$($mergedConfig.name)`\$($options.username)"
                    #        }
                    #    }
                    #}

                    $resolverPath = "$moduleRoot\Resolvers\$resolver"
                    if (Test-Path -Path $resolverPath) {
                        # Let's avoid repeatadly calling the resolver if we're getting the same credential
                        # Instead, we'll compute a checksum of the options and store the credential in a cache
                        # We'll lookup the credential by the checksum in the cache first before we go out to the resolver
                        $json = ConvertTo-Json -InputObject $options
                        $hash = _getHash -Text $json
                        if ($credentialCache.ContainsKey($hash)) {
                            $cred = $credentialCache.$hash
                            Write-Verbose -Message "Found credential [$hash] in cache"
                        } else {
                            $cred = & $resolverPath\Resolve.ps1 -options $options
                            $credentialCache.$hash = $cred
                        }
                        $secrets.$key.credential = $cred

                        # If the guest credential doesn't have a domain or computer name
                        # as part of the username, make sure to add it
                        if ($key -eq 'guest') {
                            if ($cred.UserName -notcontains '\') {
                                $userName = "$($resource.Name)`\$($cred.UserName)"
                                $tCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($userName, $cred.Password)
                                $secrets.$key.credential = $tCred
                            }
                        }
                    }
                }

                $obj = _ConvertFrom-Hashtable -hashtable $resource -combine -recurse
                $configs += $obj
                #$configs += $resource
            }
        }
    }
    $configs
}