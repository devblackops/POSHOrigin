param(
    $x
)

Import-DscResource -ModuleName POSHOrigin_Example

POSHFolder $x.Name {
    Name = $x.Name
    Ensure = $x.options.Ensure
    Path = $x.options.path
}