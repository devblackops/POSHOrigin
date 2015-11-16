function _CopyObject {
    # http://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell
    [outputtype([system.object])]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [system.object]$DeepCopyObject = $null
    )

    $memStream = new-object -TypeName IO.MemoryStream
    $formatter = new-object -TypeName Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($memStream,$DeepCopyObject)
    $memStream.Position=0
    $copy = $formatter.Deserialize($memStream)
    return $copy
}