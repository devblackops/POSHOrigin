param(
    $x
)

#Maybe try returning this as a string?

ARecord $x.Name {
    Ensure = $x.options.Ensure
    Name = $x.Name
    IPAddress = ([IPAddress]::Parse($x.options.IPAddress).ToString())
    ZoneName = $x.options.ZoneName
    DnsServer = $x.options.DnsServer
    Credential = $x.options.Secrets.DNSAdmin.Credential
    AllowUpdateAny = $x.options.AllowUpdateAny
    CreatePtr = $x.options.CreatePtr
    TTL = $x.options.TTL
    AgeRecord = $x.options.AgeRecord
}