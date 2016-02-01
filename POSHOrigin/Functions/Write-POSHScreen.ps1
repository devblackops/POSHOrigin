enum MessageType {
    Standard = [ConsoleColor]::White
    File = [ConsoleColor]::Cyan
    Module = [ConsoleColor]::Magenta
    Resource = [ConsoleColor]::Yellow
    ResourceDetail = [ConsoleColor]::Green
}

enum MsgTypeDepth {
    Standard = 0
    File = 1
    Module = 2
    Resource = 3
    ResourceDetail = 4
}

function Write-POSHScreen {
    [cmdletbinding()]
    param(
        #[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Message = [string]::empty,
        [MessageType]$OutputType = [MessageType]::Standard
    )

    $depth = [MsgTypeDepth]::$OutputType

    if ($depth -ne 0) {
        $margin = " " * $depth
    } else {
        $margin = ''
    }
    
    $msg = $margin + $Message

    $global:results = _WriteScreen -Object $msg -OutputType $OutputType
}