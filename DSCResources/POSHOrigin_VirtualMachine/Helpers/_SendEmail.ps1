Function _SendEmail {
    [cmdletbinding()]
	Param(
        [Parameter(Mandatory)]
        [string]$SmtpServer,

        [Parameter(Mandatory)]
	    [string[]]$To,

        [Parameter(Mandatory)]
		[string]$From,

        [Parameter(Mandatory)]
		[string]$subject,

        [Parameter(Mandatory)]
		[string]$body,
		
        [switch]$Html,

        [string]$Attachment
    )

	$msg = New-Object Net.Mail.MailMessage
	if ($Attachment) {
		$att = New-Object Net.Mail.Attachment($Attachment)
        $msg.Attachments.Add($att)
	}

	$smtp = New-Object Net.Mail.SmtpClient($SmtpServer)

	$msg.From = $From

	$To | ForEach-Object {
		$msg.To.Add($_)
	}

	$msg.Subject = $Subject
	$msg.Body = $Body

    if ($PSBoundParameters.ContainsKey('Html')) {
		$msg.IsBodyHtml = $true
	}

	$smtp.Send($msg)
}