param(
    [switch]$Apply,
    [switch]$IncludeFailed,
    [switch]$IncludeDeadLetter
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

$Now = Get-Date
$Actions = New-Object System.Collections.Generic.List[object]

$ProcessingTimeout = [int]$Policy.maintenance.processing_timeout_seconds
$ProcessingCutoff = $Now.AddSeconds(-$ProcessingTimeout)

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath (Get-AIOfficeMessageQueuePath -Queue "processing") `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Message = Read-AIOfficeMessagingJson -Path $File.FullName

    if ($null -eq $Message) {
        continue
    }

    $UpdatedAt = [datetime]$Message.updated_at

    if ($UpdatedAt -le $ProcessingCutoff) {
        $Actions.Add([pscustomobject]@{
            action = "timeout_to_failed"
            message_id = [string]$Message.message_id
            source_queue = "processing"
            target_queue = "failed"
        })

        if ($Apply) {
            & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Reason "Processing timeout exceeded." `
                -Actor "message-maintenance" |
                Out-Null
        }
    }
}

$ProcessedDays = [int]$Policy.maintenance.archive_processed_after_days
$ProcessedCutoff = $Now.AddDays(-$ProcessedDays)

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath (Get-AIOfficeMessageQueuePath -Queue "processed") `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    if ($File.LastWriteTime -le $ProcessedCutoff) {
        $Actions.Add([pscustomobject]@{
            action = "archive"
            message_id = $File.BaseName
            source_queue = "processed"
            target_queue = "archive"
        })

        if ($Apply) {
            & ".\scripts\messaging\Archive-AIOfficeMessage.ps1" `
                -MessageId $File.BaseName `
                -Actor "message-maintenance" |
                Out-Null
        }
    }
}

if ($IncludeFailed) {
    $FailedDays = [int]$Policy.maintenance.archive_failed_after_days
    $FailedCutoff = $Now.AddDays(-$FailedDays)

    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath (Get-AIOfficeMessageQueuePath -Queue "failed") `
            -Filter "MSG-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        if ($File.LastWriteTime -le $FailedCutoff) {
            $Actions.Add([pscustomobject]@{
                action = "archive"
                message_id = $File.BaseName
                source_queue = "failed"
                target_queue = "archive"
            })

            if ($Apply) {
                & ".\scripts\messaging\Archive-AIOfficeMessage.ps1" `
                    -MessageId $File.BaseName `
                    -Actor "message-maintenance" |
                    Out-Null
            }
        }
    }
}

if ($IncludeDeadLetter) {
    $DeadLetterDays = [int]$Policy.maintenance.archive_dead_letter_after_days
    $DeadLetterCutoff = $Now.AddDays(-$DeadLetterDays)

    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath (Get-AIOfficeMessageQueuePath -Queue "dead-letter") `
            -Filter "MSG-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        if ($File.LastWriteTime -le $DeadLetterCutoff) {
            $Actions.Add([pscustomobject]@{
                action = "archive"
                message_id = $File.BaseName
                source_queue = "dead-letter"
                target_queue = "archive"
            })

            if ($Apply) {
                & ".\scripts\messaging\Archive-AIOfficeMessage.ps1" `
                    -MessageId $File.BaseName `
                    -Actor "message-maintenance" |
                    Out-Null
            }
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

Write-Host (
    "Message maintenance identified " +
    $Actions.Count.ToString() +
    " action(s)." +
    $(if ($Apply) { " Changes applied." } else { " Preview only." })
) -ForegroundColor Green

return @($Actions | ForEach-Object { $_ })
