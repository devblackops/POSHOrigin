function _GetBlankResource {
    param(
        [parameter(mandatory)]
        [string]$Type
    )

    $x = @{}
    switch ($Type) {
        'netscaler_vip' {
            $x = @{
                Name = ''
                Vip = ''
                Port = 0
            }
        }
        'vsphere_vm' {
            $x = @{
                Name = ''
            }
        }
        default {
            throw 'Unknown resource type!'
        }
    }
    return $x
}