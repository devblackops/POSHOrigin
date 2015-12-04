<#
.SYNOPSIS
    Creates a key object based on PEM data passed to the function

.DESCRIPTION
    BouncyCastle encryption does not read in a PEM file directly, it has to be
    imported so that it is converted to an object.

    This function checks to see if the PEM that has been passed is actually 
    a string representation of the PEM file or a path to the file.

    If it is a file then it is read into a string.

    Finally another check is performed to determine if the key supplied is the
    Public or the Private key.  This is so that the object can be setup correctly.
#>
param (
    [string]
    # Path to the Pem file or a string representation of it
    $pem
)

& "$PSScriptRoot\_InitializeBouncyCastle.ps1"

# See if the pem begins with -----BEGIN 
# If it does then the pem file has been passed raw and does not need to be read in from the 
# file system
if (!($pem.StartsWith("-----BEGIN "))) {
    $pem = Get-Content -Path $pem -raw
}

# Read the string in as a stream so it can be used by bouncycastle
$stream = New-Object System.IO.StringReader $pem

$pr = New-Object Org.BouncyCastle.OpenSsl.PemReader $stream

# Determine if the key that has been passed is the public key
# This has implications for how the objects are created
if ($pem.StartsWith("-----BEGIN PUBLIC KEY-----")) {
    $key = [Org.BouncyCastle.Crypto.AsymmetricKeyParameter] ($pr.ReadObject())
} else {
    $key = [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair] ($pr.ReadObject())
}

$pr.Reader.Close()
$pr.Reader.Dispose()

$stream.Close()
$stream.Dispose()

return $key