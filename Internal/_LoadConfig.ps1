function _LoadConfig{
    [cmdletbinding()]
    param(
        [string]$Path = (_GetOption -Option 'configs_path')
    )

    Write-Verbose -Message "Configuration path: $path"

    $defaults = $null
    $veConfigs = @()
    $credentialCache = @{}

    function _loadConfigRecuse {
        [cmdletbinding()]
        param(
            [string]$dir,
            $defaults = $null,
            $configs = @()
        )

        # Search for any configurations at the same level as the defaults.psd1 file
        $localDirConfigs = @()

        $item = Get-Item -Path $dir
        if ($item.PSIsContainer) {
            $configFiles = Get-ChildItem -Path $item -Filter '*.ps1'
        } else {
            $configFiles = $item
        }

        Write-Verbose -Message "$($dir): $($configFiles.Count)"
        if ($configFiles.Count -gt 0) {
            $defaults = _LoadDefaults -Path $dir

            $configFiles | ForEach-Object {
                # Load config and merge with defaults
                $filePath = $_.FullName
                Write-Verbose -Message "Processing file [ $filePath ]"
                $config = @(. $filePath)
                if ($null -ne $config) {

                    # The file could have returned multiple hashtables
                    # let's loop through them all
                    foreach ($item in $config) {
                        $copy = _CopyObject -DeepCopyObject $item
                        $defCopy = _CopyObject -DeepCopyObject $defaults
                        Write-Verbose -Message "Processing config [ $($copy.Name) ]"

                        # Perform a deep copy of the config to ensure each config
                        # doesn't share any references to each other
                        if ($null -ne $defCopy) {
                            #$mergedConfig = _CopyObject -DeepCopyObject (_MergeHashtables -First $defaults -Second $copy)
                            $mergedConfig = _CopyObject -DeepCopyObject (_MergeHashtables -Primary $copy -Secondary $defCopy)
                        } else {
                            #Write-Warning -Message "No defaults.psd1 file found for $($copy.Name). Configuration may not be complete for this entry."
                            $mergedConfig = _CopyObject -DeepCopyObject $copy
                        }

                        #Write-Verbose -Message 'Merged Config'
                        #Write-Verbose -Message (ConvertTo-Json -InputObject $mergedConfig)

                        # Inspect the secrets
                        $secrets = $mergedConfig.options.secrets
                        foreach ($key in $secrets.keys) {
                            Write-Debug -Message "Processing secret $($mergedConfig.Name).$key"
                            $secret = $secrets.$key
                            $resolver = $secret.resolver
                            $options = $secret.options

                            if ($key -eq 'guest') {
                                if ($options.ContainsKey('username')) {
                                    # if the guest credential doesn't have a domain or computer name
                                    # as part of the username, make sure to add it
                                    if ($options.username -notcontains '\') {
                                        $options.username = "$($mergedConfig.name)`\$($options.username)"
                                    }
                                }
                            }

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
                            }
                        }

                        $obj = _ConvertFrom-Hashtable -hashtable $mergedConfig -combine -recurse
                        $localDirConfigs += $obj
                    }
                }
            }
        }

        # Add configs to our collection
        if ($localDirConfigs.Count -gt 0) {
            $localDirConfigs | ForEach-Object {
                $configs += $_
            }
        }

        # Get more configs in subdirectories
        if ($item.PSIsContainer) {
            Get-ChildItem -Path $dir -Directory |
                Where-Object { -Not($_.Name.ToLower()).Equals('common') -and
                               -Not($_.Name.ToLower()).Equals('.settings')
                             } | ForEach-Object {
                    $configs += _loadConfigRecuse -dir $_.FullName -defaults $defaults
            }
        }
        return $configs
    }

    $path = Resolve-Path -Path $Path
    $veConfigs = @(_loadConfigRecuse -dir $Path)

    return $veConfigs
}