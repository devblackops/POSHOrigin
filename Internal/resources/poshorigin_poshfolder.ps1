param (
    $x
)

POSHFolder $x.Name {
    Name = $x.options.Name
    Ensure = $x.options.Ensure
    Path = $x.options.path
}
