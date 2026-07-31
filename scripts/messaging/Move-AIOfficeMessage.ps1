param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [Parameter(Mandatory=$true)]
    [ValidateSet(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )]
    [string]$DestinationQueue,
    [string]$Actor = "message-bus",
    [string]$Details = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Queues = @(
    "inbox",
    "outbox",
    "processing",
    "processed",
    "failed",
    "dead-letter",
    "archive"
)

$SourcePath = $null
$SourceQueue = ""

foreach ($Queue in $Queues) {
    $Candidate = Join-Path `
        (Get-AIOfficeMessageQueuePath -Queue $Queue) `
        ($MessageId + ".json")

    if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
        $SourcePath = $Candidate
        $SourceQueue = $Queue
        break
    }
}

if ($null -eq $SourcePath) {
    throw "Message not found: $MessageId"
}

if ($SourceQueue -eq $DestinationQueue) {
    Write-Host (
        "Message already in " +
        $DestinationQueue +
        ": " +
        $MessageId
    ) -ForegroundColor Yellow

    return Read-AIOfficeMessagingJson -Path $SourcePath
}

$Message = Read-AIOfficeMessagingJson -Path $SourcePath

if ($null -eq $Message) {
    throw "Message JSON could not be read: $MessageId"
}

$Now = (Get-Date).ToString("o")

$DestinationPath = Join-Path `
    (Get-AIOfficeMessageQueuePath -Queue $DestinationQueue) `
    ($MessageId + ".json")

$Message.status = switch ($DestinationQueue) {
    "processing" { "processing" }
    "processed" { "completed" }
    "failed" { "failed" }
    "dead-letter" { "dead_lettered" }
    "archive" { "archived" }
    default { "queued" }
}

$Message.updated_at = $Now

if ($null -eq $Message.metadata) {
    $Message.metadata = [pscustomobject]@{}
}

if ($null -ne $Message.metadata.PSObject.Properties["queue"]) {
    $Message.metadata.queue = $DestinationQueue
}
else {
    $Message.metadata | Add-Member `
        -MemberType NoteProperty `
        -Name "queue" `
        -Value $DestinationQueue
}

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in (ConvertTo-AIOfficeMessageArray $Message.history)) {
    $History.Add($Entry)
}

if ([string]::IsNullOrWhiteSpace($Details)) {
    $Details = (
        "Message moved from " +
        $SourceQueue +
        " to " +
        $DestinationQueue +
        "."
    )
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "moved"
    actor = $Actor
    details = $Details
})

$Message.history = @(
    $History | ForEach-Object { $_ }
)

Write-AIOfficeMessagingJson `
    -Value $Message `
    -Path $DestinationPath

Remove-Item -LiteralPath $SourcePath -Force

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

Write-Host (
    "Message moved: " +
    $MessageId +
    " | " +
    $SourceQueue +
    " -> " +
    $DestinationQueue
) -ForegroundColor Green

return $Message
