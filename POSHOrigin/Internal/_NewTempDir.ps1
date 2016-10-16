function _NewTempDir {
    $parent = [System.IO.Path]::GetTempPath()
    $name = New-Guid
    $dir = New-Item -ItemType Directory -Path (Join-Path -Path $parent -ChildPath (New-Guid))
    $dir
}
