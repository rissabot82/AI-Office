param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [string]$Actor = "message-archiver"
)

$ErrorActionPreference = "Stop"

return & (Join-Path $PSScriptRoot "Move-AIOfficeMessage.ps1") `
    -MessageId $MessageId `
    -DestinationQueue "archive" `
    -Actor $Actor `
    -Details "Message archived."
