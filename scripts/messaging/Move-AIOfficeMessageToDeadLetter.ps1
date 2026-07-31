param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [string]$Reason = "Message moved to dead-letter queue.",
    [string]$Actor = "message-bus"
)

$ErrorActionPreference = "Stop"

return & (Join-Path $PSScriptRoot "Move-AIOfficeMessage.ps1") `
    -MessageId $MessageId `
    -DestinationQueue "dead-letter" `
    -Actor $Actor `
    -Details $Reason
