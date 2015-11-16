function _WriteLog {
    [cmdletbinding()]
    param(
        [string]$Message,

        [ValidateSet('Info','Verbose','Debug')]
        [string]$LogLevel = 'Info'
    )


}