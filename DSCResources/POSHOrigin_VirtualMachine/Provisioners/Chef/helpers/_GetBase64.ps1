param (
    $data
)

# if the $data is a string then ensure it is a byte array
if ($data.GetType().Name -eq "String") {
    $data = [System.Text.Encoding]::UTF8.GetBytes($data)
}

# Return the base64 representation of the string
[System.Convert]::ToBase64String($data)