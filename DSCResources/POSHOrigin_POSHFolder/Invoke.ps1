param(
    $Options
)

$hash = @{
    Name = $options.Name
    Ensure = $options.options.Ensure
    Path = $options.options.Path
}

return $hash