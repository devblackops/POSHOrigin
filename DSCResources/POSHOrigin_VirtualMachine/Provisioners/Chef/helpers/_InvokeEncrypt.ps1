[CmdletBinding()]
param (
    # String to encrypt
    $data,

    [alias('pemPath')]
    # the item in the config to use to sign the data
    $pem,

    [switch]
    # The default way to encrypt with RSA is to use the public key
    # By setting this switch the private key will be used instead
    $private
)

# determine if the path to the key specified in the configuration is an absolute URL 
# or if not then build up the path relative to the module directory
#if ([System.IO.Path]::IsPathRooted($script:session.config.$keyitem)) {
#	$signing_key = $script:session.config.$keyitem
#} else {
#	$signing_key = "{0}\{1}" -f $script:session.config.paths.conf, $script:session.config.$keyitem
#}

& "$PSScriptRoot\_InitializeBouncyCastle.ps1"

$keys = & "$PSScriptRoot\_GetKeyPairFromPem.ps1" -pem $pem

$engine = New-Object Org.BouncyCastle.Crypto.Encodings.Pkcs1Encoding (New-Object Org.BouncyCastle.Crypto.Engines.RsaEngine)

# use the public or private key for encryption, if the keys is a valid object
if ($keys -is [Org.BouncyCastle.Crypto.AsymmetricCipherKeyPair]) {
    # this is a valid key pair so the choice of public or private key encryption is allowed
    if ($private) {
        $engine.Init($true, $keys.Private)
    } else {
        $engine.Init($true, $keys.Public)
    }
} elseif ($keys -is [Org.BouncyCastle.Crypto.Parameters.RsaKeyParameters]) {	
    # only the public key has been passed so just add the key to initialise the engine
    $engine.Init($true, $keys)
}

# Get a byte array from the data if it is a string
if ($data -is [String]) {
    $encoding = New-Object System.Text.ASCIIEncoding
    $dataBytes = $encoding.GetBytes($data)
} elseif ($data -is [Byte[]]) {
    $dataBytes = $data
}

$encrypted = $engine.ProcessBlock($dataBytes, 0, $dataBytes.Length)

# Delete temporary key
#Remove-Item -Path $pem -Force

# return the base64 encoded string
return [Convert]::ToBase64String($encrypted)