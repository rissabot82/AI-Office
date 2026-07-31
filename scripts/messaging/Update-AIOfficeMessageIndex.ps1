param()

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

$Counts = @{}
$AllFiles = New-Object System.Collections.Generic.List[object]

foreach ($Queue in $Queues) {
    $Path = Get-AIOfficeMessageQueuePath -Queue $Queue

    $Files = @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Filter "MSG-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )

    $Counts[$Queue] = $Files.Count

    foreach ($File in $Files) {
        $AllFiles.Add($File)
    }
}

$Latest = $AllFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$LatestId = ""
$LatestAt = ""

if ($null -ne $Latest) {
    $LatestId = $Latest.BaseName
    $LatestAt = $Latest.LastWriteTime.ToString("o")
}

$Index = [ordered]@{
    schema_version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    total_messages = [int]$AllFiles.Count
    inbox_count = [int]$Counts["inbox"]
    outbox_count = [int]$Counts["outbox"]
    processing_count = [int]$Counts["processing"]
    processed_count = [int]$Counts["processed"]
    failed_count = [int]$Counts["failed"]
    dead_letter_count = [int]$Counts["dead-letter"]
    archive_count = [int]$Counts["archive"]
    latest_message_id = $LatestId
    latest_message_at = $LatestAt
    status = if ($AllFiles.Count -gt 0) { "active" } else { "empty" }
}

Write-AIOfficeMessagingJson `
    -Value $Index `
    -Path ".\workspace\messages\message-index.json"

Write-Host (
    "Message index updated: " +
    $AllFiles.Count.ToString() +
    " message(s)."
) -ForegroundColor Green

return [pscustomobject]$Index
