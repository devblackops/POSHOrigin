# Load the Bouncycastle library without locking the DLL or needlessly re-loading
try {
    $assemblyLoaded = New-Object Org.BouncyCastle.Crypto.Engines.RsaEngine -ErrorAction SilentlyContinue
} catch {
    $dll = Join-Path -Path $PSScriptRoot -ChildPath 'BouncyCastle.Crypto.dll'
    if ( !(Test-Path $dll) ) {
        throw "Unable to find the BouncyCastle library: $dll"
    }
    
    $fileStream = ([System.IO.FileInfo] (Get-Item -Path $dll)).OpenRead()
    $assemblyBytes = New-Object -TypeName byte[] -ArgumentList $fileStream.Length
    $fileStream.Read($assemblyBytes, 0, $fileStream.Length) | Out-Null
    $fileStream.Close()
    $assemblyLoaded = [System.Reflection.Assembly]::Load($assemblyBytes);
}