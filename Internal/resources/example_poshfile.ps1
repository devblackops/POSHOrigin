param(
    $x
)

Import-DscResource -ModuleName POSHOrigin_Example

POSHFile $x.Name {
    Name = $x.Name
    Ensure = $x.options.Ensure
    Path = $x.options.path
    Contents = $x.options.contents
}