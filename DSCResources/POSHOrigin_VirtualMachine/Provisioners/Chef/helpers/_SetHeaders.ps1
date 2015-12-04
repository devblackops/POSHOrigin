<#
.SYNOPSIS
Build up the headers that are required for a chef API query

.DESCRIPTION
Function to build up the headers for the query against the chef server.

It will also build up the hash that is required for the body and then sign it
#>
param (
    [string]
    $path,

    [string]
    $method = "GET",

    $data,

    [hashtable]
    $headers,

    [string]
    # Attribute in the chefconfig to use as the UserId
    $useritem = "client",

    [Alias('KeyPath')]
    [string]    
    $Key

    #[string]
    # Attribute in the chefconfig to use as the key
    #$keyitem = "key"
)

# generate a timestamp, this must be UTC
$timestamp = Get-Date -Date ([DateTime]::UTCNow) -uformat "+%Y-%m-%dT%H:%M:%SZ"

# Determine the SHA1 hash of the content
$content_hash = & "$PSScriptRoot\_GetCheckSum.ps1" -string $data -algorithm SHA1

# define the headers hash table
$headers = @{
    'X-Ops-Sign' = 'algorithm=sha1;version=1.0'
    'X-Ops-UserId' = $useritem
    'X-Ops-Timestamp' = $timestamp
    'X-Ops-Content-Hash' = $content_hash
    'X-Chef-Version' = '12.0.2'
}

# Create ArrayList to hold the parts of the header that need to be encrypted
$al = New-Object System.Collections.ArrayList

$al.Add(("Method:{0}" -f $method.ToUpper())) | Out-Null
$al.Add(("Hashed Path:{0}" -f $(& "$PSScriptRoot\_GetCheckSum.ps1" -string $path -algorithm SHA1))) | Out-Null
$al.Add(("X-Ops-Content-Hash:{0}" -f $content_hash)) | Out-Null
$al.Add(("X-Ops-Timestamp:{0}" -f $timestamp)) | Out-Null
$al.Add(("X-Ops-UserId:{0}" -f $useritem.trim())) | Out-Null

$canonicalized_header = $al -join "`n"

## Build up the path to the pem.  this might be an absolute path in which case use that
#if ([System.IO.Path]::IsPathRooted($script:session.config.$keyitem)) {
#		$pempath = $script:session.config.$keyitem
#	} else {
#		$pempath = Join-Path $script:session.config.paths.conf $script:session.config.$keyitem
#	}
#$pemPath = 'C:\Users\bolin\chef-repo\.chef\bolin.pem'

$cipher = & "$PSScriptRoot\_InvokeEncrypt.ps1" -data $canonicalized_header -pem $Key -private

# the signature now needs to be split into lines of 60 characters each
$signature = $cipher -split "(.{60})" | Where-Object {$_}

# Add the signature to the header
$loop = 1
$signature.split("`r") | Foreach-Object {
    # Add each bit to the header
    $headers[$("X-Ops-Authorization-{0}" -f $loop)] = $_

    # increment the counter
    $loop ++
}

# return the headers to the calling function
return $headers