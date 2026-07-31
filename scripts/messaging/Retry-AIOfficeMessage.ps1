param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [ValidateSet("inbox","outbox")]
    [string]$ReturnQueue = "inbox",
    [string]$Actor = "message-retry"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Policy = Read-AIOfficeMessagingJson `
    -Path ".\config\messaging\processing-policy.json"

if ($null -eq $Policy) {
    throw "Processing policy could not be loaded."
}

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

if ([string]$Message.current_queue -ne "failed") {
    throw "Only failed messages can be retried. Current queue: $($Message.current_queue)"
}

$Attempts = [int]$Message.delivery_attempts
$MaximumAttempts = [int]$Policy.retry.max_delivery_attempts

if ($Attempts -ge $MaximumAttempts) {
    return & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
        -MessageId $MessageId `
        -DestinationQueue "dead-letter" `
        -Actor $Actor `
        -Details (
            "Maximum delivery attempts reached (" +
            $Attempts.ToString() +
            "). Message moved to dead-letter."
        )
}

$BaseDelay = [int]$Policy.retry.base_delay_seconds
$Multiplier = [double]$Policy.retry.backoff_multiplier
$MaxDelay = [int]$Policy.retry.maximum_delay_seconds

$DelaySeconds = [int][math]::Round(
    $BaseDelay * [math]::Pow($Multiplier, [math]::Max(0, $Attempts - 1))
)

if ($DelaySeconds -gt $MaxDelay) {
    $DelaySeconds = $MaxDelay
}

$FailedPath = Join-Path `
    (Get-AIOfficeMessageQueuePath -Queue "failed") `
    ($MessageId + ".json")

$StoredMessage = Read-AIOfficeMessagingJson -Path $FailedPath

if ($null -eq $StoredMessage) {
    throw "Failed message could not be read: $MessageId"
}

$AvailableAt = (Get-Date).AddSeconds($DelaySeconds).ToString("o")
$StoredMessage.available_at = $AvailableAt
$StoredMessage.updated_at = (Get-Date).ToString("o")

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in (ConvertTo-AIOfficeMessageArray $StoredMessage.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = (Get-Date).ToString("o")
    action = "retry_scheduled"
    actor = $Actor
    details = (
        "Retry scheduled in " +
        $DelaySeconds.ToString() +
        " seconds for queue " +
        $ReturnQueue +
        "."
    )
})

$StoredMessage.history = @($History | ForEach-Object { $_ })

Write-AIOfficeMessagingJson -Value $StoredMessage -Path $FailedPath

return & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
    -MessageId $MessageId `
    -DestinationQueue $ReturnQueue `
    -Actor $Actor `
    -Details (
        "Message returned for retry. Available at " +
        $AvailableAt +
        "."
    )
