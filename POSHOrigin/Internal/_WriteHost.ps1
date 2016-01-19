
enum MsgType {
    File = [ConsoleColor]::Magenta
    Module = [ConsoleColor]::Cyan
    Resource = [ConsoleColor]::Yellow
    ResourceDetail = [ConsoleColor]::Green
}

enum MsgTypeDepth {
    File = 1
    Module = 2
    Resource = 3
    ResourceDetail = 4
}

function _WriteHost {
    param(
        [string]$Message,
        [MsgType]$MsgType = [MsgType]::File
    )

    $depth = [MsgTypeDepth]::$MsgType
    $marge = " " * $depth

    $margin + $Message | _WriteScreen -OutputType $MsgType
}