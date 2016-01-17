[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [psobject]$Options = $null
)

begin {
    Write-Debug -Message $msgs.rslv_protecteddata_begin
}

process {
    
}

end {
    Write-Debug -Message $msgs.rslv_protecteddata_end
}