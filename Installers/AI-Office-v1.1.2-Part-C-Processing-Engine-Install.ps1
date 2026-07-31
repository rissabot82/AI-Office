# ============================================================
# AI Office v1.1.2 - Part C
# Processing Engine
# Repository: E:\AI\AI-Office
# Requires: v1.1.2 Parts A and B
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\scripts\messaging\AIOfficeMessaging.Common.ps1",
    ".\scripts\messaging\Move-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.2 Parts A and B are required. Missing: $RequiredPath"
    }
}

function Write-NewFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $Parent = Split-Path -Parent $Path

        if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
            New-Item -ItemType Directory -Path $Parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

$ProcessingPolicy = @'
{
  "schema_version": "1.0.0",
  "version": "1.1.2",
  "part": "C",
  "retry": {
    "enabled": true,
    "max_delivery_attempts": 3,
    "base_delay_seconds": 30,
    "backoff_multiplier": 2,
    "maximum_delay_seconds": 900
  },
  "dead_letter": {
    "enabled": true,
    "move_after_max_attempts": true
  },
  "maintenance": {
    "processing_timeout_seconds": 300,
    "archive_processed_after_days": 30,
    "archive_failed_after_days": 30,
    "archive_dead_letter_after_days": 90
  },
  "processor": {
    "default_batch_size": 10,
    "maximum_batch_size": 100,
    "continue_on_error": true
  },
  "updated_at": ""
}
'@

Write-NewFile ".\config\messaging\processing-policy.json" $ProcessingPolicy

$RetryScript = @'
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
'@

Write-NewFile ".\scripts\messaging\Retry-AIOfficeMessage.ps1" $RetryScript

$DeadLetterScript = @'
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
'@

Write-NewFile ".\scripts\messaging\Move-AIOfficeMessageToDeadLetter.ps1" $DeadLetterScript

$RecoverScript = @'
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
'@

Write-NewFile ".\scripts\messaging\Recover-AIOfficeDeadLetterMessage.ps1" $RecoverScript

$ArchiveScript = @'
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
'@

Write-NewFile ".\scripts\messaging\Archive-AIOfficeMessage.ps1" $ArchiveScript

$MaintenanceScript = @'
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
'@

Write-NewFile ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1" $MaintenanceScript

$ProcessorScript = @'
param(
    [ValidateSet("inbox","outbox")]
    [string]$Queue = "inbox",
    [string]$Recipient = "",
    [int]$BatchSize = 10,
    [switch]$AutoComplete,
    [switch]$StopOnError
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

$MaximumBatch = [int]$Policy.processor.maximum_batch_size

if ($BatchSize -lt 1) {
    $BatchSize = 1
}

if ($BatchSize -gt $MaximumBatch) {
    $BatchSize = $MaximumBatch
}

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $BatchSize; $Index++) {
    try {
        $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
            -Queue $Queue `
            -Recipient $Recipient

        if ($null -eq $Message) {
            break
        }

        $Result = [ordered]@{
            message_id = [string]$Message.message_id
            status = "claimed"
            queue = "processing"
            error = ""
        }

        if ($AutoComplete) {
            & ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Actor "batch-processor" |
                Out-Null

            & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
                -MessageId ([string]$Message.message_id) `
                -Actor "batch-processor" `
                -Details "Message automatically completed by batch processor." |
                Out-Null

            $Result.status = "completed"
            $Result.queue = "processed"
        }

        $Results.Add([pscustomobject]$Result)
    }
    catch {
        $Results.Add([pscustomobject]@{
            message_id = ""
            status = "error"
            queue = $Queue
            error = $_.Exception.Message
        })

        if ($StopOnError) {
            break
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

Write-Host (
    "Processor handled " +
    $Results.Count.ToString() +
    " message(s)."
) -ForegroundColor Green

return @($Results | ForEach-Object { $_ })
'@

Write-NewFile ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1" $ProcessorScript

$RequeueFailedScript = @'
param(
    [ValidateSet("inbox","outbox")]
    [string]$ReturnQueue = "inbox",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Files = @(
    Get-ChildItem `
        -LiteralPath (Get-AIOfficeMessageQueuePath -Queue "failed") `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime |
        Select-Object -First $Limit
)

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in $Files) {
    try {
        $Message = & ".\scripts\messaging\Retry-AIOfficeMessage.ps1" `
            -MessageId $File.BaseName `
            -ReturnQueue $ReturnQueue

        $Results.Add([pscustomobject]@{
            message_id = $File.BaseName
            result = [string]$Message.status
        })
    }
    catch {
        $Results.Add([pscustomobject]@{
            message_id = $File.BaseName
            result = "error: " + $_.Exception.Message
        })
    }
}

return @($Results | ForEach-Object { $_ })
'@

Write-NewFile ".\scripts\messaging\Retry-AIOfficeFailedMessages.ps1" $RequeueFailedScript

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Part C Processing Engine..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$Required = @(
    ".\config\messaging\processing-policy.json",
    ".\scripts\messaging\Retry-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessageToDeadLetter.ps1",
    ".\scripts\messaging\Recover-AIOfficeDeadLetterMessage.ps1",
    ".\scripts\messaging\Archive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1",
    ".\scripts\messaging\Retry-AIOfficeFailedMessages.ps1",
    ".\scripts\messaging\Test-AIOfficeProcessingEngine.ps1"
)

foreach ($Path in $Required) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Write-Host "[FOUND] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[MISS ] $Path" -ForegroundColor Red
        $Errors.Add("Missing file: " + $Path)
    }
}

try {
    Get-Content ".\config\messaging\processing-policy.json" -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] processing-policy.json" `
        -ForegroundColor Green
}
catch {
    Write-Host "[JSON ERROR] processing-policy.json" `
        -ForegroundColor Red
    $Errors.Add("Invalid processing-policy.json")
}

$TestIds = New-Object System.Collections.Generic.List[string]

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "analytics" `
        -To "chief-of-staff" `
        -MessageType "error" `
        -Priority "high" `
        -Subject "Part C retry test" `
        -ConversationTopic "RETRY-TEST" `
        -Queue "processing" `
        -PayloadJson '{"test":"retry"}'

    $TestIds.Add([string]$Message.message_id)

    & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id) `
        -Reason "Retry validation" |
        Out-Null

    & ".\scripts\messaging\Retry-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id) `
        -ReturnQueue "inbox" |
        Out-Null

    $Retried = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id)

    if ([string]$Retried.current_queue -ne "inbox") {
        throw "Retry did not return message to inbox."
    }

    Write-Host "[RETRY OK  ] Retry scheduling passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[RETRY ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Retry test failed: " + $_.Exception.Message)
}

try {
    $DeadMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "bridge" `
        -To "chief-of-staff" `
        -MessageType "error" `
        -Priority "urgent" `
        -Subject "Part C dead-letter test" `
        -ConversationTopic "DEAD-LETTER-TEST" `
        -Queue "failed" `
        -PayloadJson '{"test":"dead-letter"}'

    $TestIds.Add([string]$DeadMessage.message_id)

    & ".\scripts\messaging\Move-AIOfficeMessageToDeadLetter.ps1" `
        -MessageId ([string]$DeadMessage.message_id) `
        -Reason "Validation dead-letter movement." |
        Out-Null

    $Dead = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$DeadMessage.message_id)

    if ([string]$Dead.current_queue -ne "dead-letter") {
        throw "Message did not move to dead-letter."
    }

    & ".\scripts\messaging\Recover-AIOfficeDeadLetterMessage.ps1" `
        -MessageId ([string]$DeadMessage.message_id) `
        -DestinationQueue "outbox" |
        Out-Null

    $Recovered = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$DeadMessage.message_id)

    if ([string]$Recovered.current_queue -ne "outbox" -or
        [int]$Recovered.delivery_attempts -ne 0) {
        throw "Dead-letter recovery state was incorrect."
    }

    Write-Host "[DEAD OK   ] Dead-letter and recovery passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[DEAD ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Dead-letter test failed: " + $_.Exception.Message)
}

try {
    $BatchOne = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "normal" `
        -Subject "Part C batch test 1" `
        -ConversationTopic "BATCH-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"test":"batch1"}'

    $BatchTwo = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "creative" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "normal" `
        -Subject "Part C batch test 2" `
        -ConversationTopic "BATCH-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"test":"batch2"}'

    $TestIds.Add([string]$BatchOne.message_id)
    $TestIds.Add([string]$BatchTwo.message_id)

    $BatchResults = @(
        & ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1" `
            -Queue "outbox" `
            -Recipient "bridge" `
            -BatchSize 2 `
            -AutoComplete
    )

    if ($BatchResults.Count -ne 2) {
        throw "Batch processor did not process two messages."
    }

    Write-Host "[BATCH OK  ] Batch processor passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[BATCH ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Batch processor test failed: " + $_.Exception.Message)
}

try {
    $Maintenance = @(
        & ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1"
    )

    Write-Host (
        "[MAINT OK  ] Preview returned " +
        $Maintenance.Count.ToString() +
        " action(s)."
    ) -ForegroundColor Green
}
catch {
    Write-Host "[MAINT ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Maintenance test failed: " + $_.Exception.Message)
}

foreach ($MessageId in $TestIds) {
    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Path = ".\workspace\messages\$Queue\$MessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " processing engine error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Part C Processing Engine checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\messaging\Test-AIOfficeProcessingEngine.ps1" $Test

$Guide = @'
# AI Office v1.1.2 Part C — Processing Engine

Part C adds message retry, dead-letter handling, maintenance, archival, and batch processing.

## Added

- Retry scheduling
- Exponential backoff
- Maximum-attempt enforcement
- Dead-letter movement
- Dead-letter recovery
- Message archival
- Processing timeout recovery
- Queue maintenance
- Batch claiming
- Optional automatic acknowledgement and completion
- Failed-message retry utility
- Processing-engine validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Test-AIOfficeProcessingEngine.ps1"
```

Expected result:

```text
All AI Office v1.1.2 Part C Processing Engine checks passed.
```

## Preview maintenance

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1"
```

## Apply maintenance

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1" `
    -Apply
```

## Next

Part D adds the complete v1.1.2 validation suite, release documentation, sample conversations, and end-to-end message-bus certification.
'@

Write-NewFile ".\docs\AI-Office-v1.1.2-Part-C-Processing-Engine.md" $Guide

Write-Host ""
Write-Host "Validating Part C configuration..." -ForegroundColor Cyan

Get-Content ".\config\messaging\processing-policy.json" -Raw |
    ConvertFrom-Json |
    Out-Null

Write-Host "[VALID JSON] .\config\messaging\processing-policy.json" `
    -ForegroundColor Green

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.1.2-Part-C-Processing-Engine-Install.ps1"

    if ($Source -and
        (Test-Path -LiteralPath $Source -PathType Leaf) -and
        [System.IO.Path]::GetFullPath($Source) -ne
        [System.IO.Path]::GetFullPath($Destination)) {
        Copy-Item `
            -LiteralPath $Source `
            -Destination $Destination `
            -Force

        Write-Host "[COPIED ] Installer saved to $Destination" `
            -ForegroundColor Green
    }
}
catch {
    Write-Host (
        "[WARNING] Installer copy was not completed: " +
        $_.Exception.Message
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "AI Office v1.1.2 Part C installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\messaging\Test-AIOfficeProcessingEngine.ps1"'
Write-Host ""
