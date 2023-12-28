Function Send-GraphEmail {
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]$MailboxSender,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]$MailboxRecipient,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]$Subject,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]$EmailBody,
      [Parameter(Mandatory = $false)]
      [ValidateNotNullOrEmpty()]
      [switch]$UseMSI
  )

If ($UseMSI) {

$Headers = @{
  "Authorization" = "Bearer $(Get-GraphAccessToken -UseMSI)"
  "Content-type"  = "application/json" }
}
Else 
{
  $Headers = @{
  "Authorization" = "Bearer $(Get-GraphAccessToken)"
  "Content-type"  = "application/json"}
}

$URLsend = "https://graph.microsoft.com/v1.0/users/$MailBoxSender/sendMail"
$JsonBodyEmail = @"
{
"message": {
"subject": "$Subject",
"body": {
"contentType": "HTML",
"content": "$EmailBody <br>
<br>
<br>
THIS IS AN AUTOMATED MESSAGE, DO NOT REPLY DIRECTLY TO THIS MESSAGE AS IT IS SENT FROM AN UNMONITORED MAILBOX <br>

"
},
"toRecipients": [
{
  "emailAddress": {
    "address": "$mailboxRecipient"
  }
}
]
},
"saveToSentItems": "false"
}
"@

$EmailSendArgs = @{
      Method  = 'POST'
      Uri     = $URLsend
      Headers = $headers
      Body    = $JsonBodyEmail
  }
  try {
  Invoke-RestMethod @EmailSendArgs
  }
  Catch {
    Write-Output "Please ensure the Runbook or User has the correct graph permissions to Send from $($MailboxSender)"
   }
}