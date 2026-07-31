param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [string]$Actor = "message-processor",
    [string]$Details = "Message processing completed."
)

$ErrorActionPreference = "Stop"

return & (Join-Path $PSScriptRoot "Move-AIOfficeMessage.ps1") `
    -MessageId $MessageId `
    -DestinationQueue "processed" `
    -Actor $Actor `
    -Details $Details
