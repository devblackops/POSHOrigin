<#
.SYNOPSIS
Gets the hash value of a file or string
 
.DESCRIPTION
Gets the hash value of a file or string
It uses System.Security.Cryptography.HashAlgorithm (http://msdn.microsoft.com/en-us/library/system.security.cryptography.hashalgorithm.aspx)
and FileStream Class (http://msdn.microsoft.com/en-us/library/system.io.filestream.aspx)
Based on: http://blog.brianhartsock.com/2008/12/13/using-powershell-for-md5-checksums/ and some ideas on Microsoft Online Help
 
Be aware, to avoid confusions, that if you use the pipeline, the behaviour is the same as using -Text, not -File
 
.PARAMETER File
File to get the hash from.
 
.PARAMETER Text
Text string to get the hash from
 
.PARAMETER Algorithm
Type of hash algorithm to use. Default is SHA1
 
.EXAMPLE
C:\PS> Get-Hash "hello_world.txt"
Gets the SHA1 from myFile.txt file. When there's no explicit parameter, it uses -File
 
.EXAMPLE
Get-Hash -File "C:\temp\hello_world.txt"
Gets the SHA1 from myFile.txt file
 
.EXAMPLE
C:\PS> Get-Hash -Algorithm "MD5" -Text "Hello Wold!"
Gets the MD5 from a string
 
.EXAMPLE
C:\PS> "Hello Wold!" | Get-Hash
We can pass a string throught the pipeline
 
.EXAMPLE
Get-Content "c:\temp\hello_world.txt" | Get-Hash
It gets the string from Get-Content
 
.EXAMPLE
Get-ChildItem "C:\temp\*.txt" | %{ Write-Output "File: $($_)   has this hash: $(Get-Hash $_)" }
This is a more complex example gets the hash of all "*.tmp" files
 
.NOTES
DBA daily stuff (http://dbadailystuff.com) by Josep Martínez Vilà
Licensed under a Creative Commons Attribution 3.0 Unported License
 
.LINK
Original post: http://dbadailystuff.com/2013/03/11/get-hash-a-powershell-hash-function/
#>
function _getHash {
     Param (
          [parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="set1")]
          [String]
          $text,

          [parameter(Position=0, Mandatory=$true, ValueFromPipeline=$false, ParameterSetName="set2")]
          [String]
          $file = "",

          [parameter(Mandatory=$false, ValueFromPipeline=$false)]
          [ValidateSet("MD5", "SHA", "SHA1", "SHA-256", "SHA-384", "SHA-512")]
          [String]
          $algorithm = "SHA1"
     )

     begin {
          $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($algorithm)
     }

     process {
          $md5StringBuilder = New-Object System.Text.StringBuilder 50
          $ue = New-Object System.Text.UTF8Encoding
 
          if ($file){

               try {
                    if (!(Test-Path -literalpath $file)){
                         throw 'Test-Path returned false.'
                    }
               } catch {
                    throw "_getHash - File not found or without permisions: [$file]. $_"
               }

               try {
                    [System.IO.FileStream]$fileStream = [System.IO.File]::Open($file, [System.IO.FileMode]::Open);
                    $hashAlgorithm.ComputeHash($fileStream) | % { [void] $md5StringBuilder.Append($_.ToString("x2")) }
               } catch {
                    throw "Get-Hash - Error reading or hashing the file: [$file]"
               }
               finally {
                    $fileStream.Close()
                    $fileStream.Dispose()
               }
          }
          else {
               $hashAlgorithm.ComputeHash($ue.GetBytes($text)) | % { [void] $md5StringBuilder.Append($_.ToString("x2")) }
          }
 
          return $md5StringBuilder.ToString()
     }
}