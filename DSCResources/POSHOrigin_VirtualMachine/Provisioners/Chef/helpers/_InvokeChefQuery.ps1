<#
.SYNOPSIS
Run the desired query against chef and pass back an object
#>
[CmdletBinding()]
param (
    [parameter(Mandatory)]
    [string]$OrgUri,

    [alias("path")]
    # Path that is being requested from the chef server
    $uri,

    [ValidateSet('GET', 'PUT', 'POST', 'DELETE')]
    [string]
    # Method to be used on the REST request
    $method = "GET",

    # Data that needs to be passed with the request
    $data = [String]::Empty,

    [string]
    # Attribute in the chefconfig to use as the UserId
    $useritem = "bolin",

    [string]
    # Attribute in the chefconfig to use as the key
    $KeyPath = "key",

    [switch]
    # Denote wether the system should get the raw data from the file
    # insetad of an object
    $raw,

    [string]
    # Content type of the request
    $contenttype = "application/json",

    [string]
    # The Md5 checksum of the content
    $data_checksum = $false,

    [switch]
    # State whether to passthru, e.g. any errors should be passed back to the calling function as well
    $passthru
)

# if the data is a hashtable convert it to a json string
if ($data -is [Hashtable] -or $data -is [System.Collections.Generic.Dictionary`2[System.String,System.Object]]) {
    $data = $data | ConvertTo-JSON -Depth ([int]::MaxValue)
}

# If the path is a string then turn it into a System URI object
if ($uri -is [String]) {
    $uri = [System.Uri] $uri

    # If the scheme is empty build up a uri based on the server in configuration and the path that has been specified
    if ([String]::IsNullOrEmpty($uri.Scheme)) {
        $uri = [System.Uri] ("{0}{1}" -f $OrgUri, $uri.OriginalString)
    }
}

# Get the content of the key path
$tmpFile = New-TemporaryFile
Invoke-WebRequest -Uri $KeyPath -OutFile $tmpFile.FullName -Verbose:$false
$key = Get-Content -Path $tmpFile -Raw
Remove-Item -Path $tmpFile -Force

#write-verbose -Message $tmpFile.FullName

# Sign the request and build up the headers
$headers = & "$PSScriptRoot\_SetHeaders.ps1" -Path $uri.AbsolutePath -Method $method -data $data -useritem $useritem -Key $key
$headers = & "$PSScriptRoot\_SetHeaders.ps1" -Path $uri.AbsolutePath -Method $method -data $data -useritem $useritem -Key $key

# if the data_checksum is not false add it to the headers
if ($data_checksum -ne $false) {
    $headers["content-md5"] = $data_checksum
}

# Build up a splat hash to pass to invoke-rest method
# this is so that the headers that the options being sent can be show in verbose mode
$splathash = @{uri = $uri.OriginalString
                headers = $headers
                method = $method
                body = $data
                contenttype = $contenttype}

# if the raw parameter has been specified then set the accept object
if ($raw) {
    $splathash.accept = "*/*"
}	

# Run the request against the chef server
$response = & "$PSScriptRoot\_InvokeChefRestMethod.ps1" @splathash

# Analyse the information that has come back from the server
if (200..204 -contains $response.statuscode) {

    # set the return value
    $return = $response.data

    # if not raw then turn the response data into a hashtable
    #if (!$raw -and ![String]::IsNullOrEmpty($return)) {
    #    $return = _ConvertFromJsonToHashtable -InputObject $return
    #}
    if (!$raw -and ![String]::IsNullOrEmpty($return)) {
        $return = ConvertFrom-Json -InputObject $return
    }
} else {
    #$content = $response.data | _ConvertFromJsonToHashtable
    $content = $response.data | ConvertFrom-Json

    # define the return variable
    $return = $content
    $return.statuscode = $response.statuscode
}

# add the api version of the server to the session variable
# this is so that plugins can use the information to determine how to work
#$script:session.apiversion = $response.apiversion

# return an object generated from the JSON
$return