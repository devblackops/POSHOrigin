function Get-POSHOriginSecret {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, Position=0)]
        [string]$Resolver,

        [parameter(Mandatory, Position=1)]
        [hashtable]$Options
    )

    # Let's avoid repeatadly calling the resolver if we're getting the same credential
    # Instead, we'll compute a checksum of the options and store the credential in a cache
    # We'll lookup the credential by the checksum in the cache first before we go out to the resolver

    $resolverPath = "$moduleRoot\Resolvers\$resolver"
    if (Test-Path -Path $resolverPath) {
        $json = ConvertTo-Json -InputObject $options
        $hash = _getHash -Text $json
        if ($script:credentialCache.ContainsKey($hash)) {
            $cred = $script:credentialCache.$hash
            Write-Verbose -Message ($msgs.gpos_cache_hit -f $hash)
        } else {
            $cred = & "$resolverPath\Resolve.ps1" -Options $options
            $script:credentialCache.Add($hash, $cred)
        }
        return $cred
    } else {
        $knownResolvers = Get-ChildItem -Path "$moduleRoot\Resolvers\" -Directory | Select-Object -ExpandProperty Name
        $knownResolversTxt = $knownResolvers -join ', '
        throw ($msgs.gpos_unknown_resolver -f $resolver, $knownResolvers)
    }
}