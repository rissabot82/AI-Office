param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [ValidateSet("inbox","outbox")]
    [string]$DestinationQueue = "inbox",
    [string]$Actor = "message-recovery"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

if ([string]$Message.current_queue -ne "dead-letter") {
    throw "Only dead-letter messages can be recovered."
}

$Path = Join-Path `
    (Get-AIOfficeMessageQueuePath -Queue "dead-letter") `
    ($MessageId + ".json")

$StoredMessage = Read-AIOfficeMessagingJson -Path $Path

$StoredMessage.delivery_attempts = 0
$StoredMessage.available_at = (Get-Date).ToString("o")
$StoredMessage.updated_at = (Get-Date).ToString("o")

if ($null -eq $StoredMessage.metadata) {
    $StoredMessage.metadata = [pscustomobject]@{}
}

if ($null -ne $StoredMessage.metadata.PSObject.Properties["last_error"]) {
    $StoredMessage.metadata.last_error = ""
}

Write-AIOfficeMessagingJson -Value $StoredMessage -Path $Path

return & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
    -MessageId $MessageId `
    -DestinationQueue $DestinationQueue `
    -Actor $Actor `
    -Details (
        "Dead-letter message recovered to " +
        $DestinationQueue +
        ". Delivery attempts reset."
    )
