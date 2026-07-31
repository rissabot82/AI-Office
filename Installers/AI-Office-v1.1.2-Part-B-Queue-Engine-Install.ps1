# ============================================================
# AI Office v1.1.2 - Part B
# Queue Engine
# Repository: E:\AI\AI-Office
# Requires: v1.1.2 Part A
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

if (-not (Test-Path -LiteralPath ".\scripts\messaging\AIOfficeMessaging.Common.ps1" -PathType Leaf)) {
    throw "AI Office v1.1.2 Part A is required before installing Part B."
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

$QueuePolicy = @'
{
  "schema_version": "1.0.0",
  "version": "1.1.2",
  "part": "B",
  "queue_order": [
    "critical",
    "urgent",
    "high",
    "normal",
    "low"
  ],
  "queue_transitions": {
    "inbox": [
      "processing",
      "failed",
      "archive"
    ],
    "outbox": [
      "processing",
      "failed",
      "archive"
    ],
    "processing": [
      "processed",
      "failed",
      "dead-letter"
    ],
    "failed": [
      "inbox",
      "outbox",
      "dead-letter",
      "archive"
    ],
    "processed": [
      "archive"
    ],
    "dead-letter": [
      "archive"
    ]
  },
  "acknowledgement_status": "acknowledged",
  "updated_at": ""
}
'@

Write-NewFile ".\config\messaging\queue-policy.json" $QueuePolicy

$MoveScript = @'
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
    Write-Host "Message already in $DestinationQueue: $MessageId" `
        -ForegroundColor Yellow
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

if ($null -ne $Message.PSObject.Properties["metadata"]) {
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
}

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in (ConvertTo-AIOfficeMessageArray $Message.history)) {
    $History.Add($Entry)
}

if ([string]::IsNullOrWhiteSpace($Details)) {
    $Details = "Message moved from $SourceQueue to $DestinationQueue."
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "moved"
    actor = $Actor
    details = $Details
})

$Message.history = @($History | ForEach-Object { $_ })

Write-AIOfficeMessagingJson -Value $Message -Path $DestinationPath
Remove-Item -LiteralPath $SourcePath -Force

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" | Out-Null

Write-Host (
    "Message moved: " +
    $MessageId +
    " | " +
    $SourceQueue +
    " -> " +
    $DestinationQueue
) -ForegroundColor Green

return $Message
'@

Write-NewFile ".\scripts\messaging\Move-AIOfficeMessage.ps1" $MoveScript

$GetScript = @'
param(
    [Parameter(Mandatory=$true)][string]$MessageId
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

foreach ($Queue in $Queues) {
    $Path = Join-Path `
        (Get-AIOfficeMessageQueuePath -Queue $Queue) `
        ($MessageId + ".json")

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $Message = Read-AIOfficeMessagingJson -Path $Path

        if ($null -eq $Message) {
            throw "Message exists but could not be parsed: $MessageId"
        }

        $Message | Add-Member `
            -MemberType NoteProperty `
            -Name "current_queue" `
            -Value $Queue `
            -Force

        return $Message
    }
}

throw "Message not found: $MessageId"
'@

Write-NewFile ".\scripts\messaging\Get-AIOfficeMessage.ps1" $GetScript

$ReceiveScript = @'
param(
    [string]$Queue = "inbox",
    [string]$Recipient = "",
    [switch]$Peek
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$QueuePath = Get-AIOfficeMessageQueuePath -Queue $Queue

$PriorityRank = @{
    critical = 1
    urgent = 2
    high = 3
    normal = 4
    low = 5
}

$Candidates = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath $QueuePath `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Message = Read-AIOfficeMessagingJson -Path $File.FullName

    if ($null -eq $Message) {
        continue
    }

    if (-not [string]::IsNullOrWhiteSpace($Recipient) -and
        [string]$Message.to -ne $Recipient) {
        continue
    }

    $AvailableAt = Get-Date

    if (-not [string]::IsNullOrWhiteSpace([string]$Message.available_at)) {
        $AvailableAt = [datetime]$Message.available_at
    }

    if ($AvailableAt -gt (Get-Date)) {
        continue
    }

    $Rank = 99

    if ($PriorityRank.ContainsKey([string]$Message.priority)) {
        $Rank = [int]$PriorityRank[[string]$Message.priority]
    }

    $Candidates.Add([pscustomobject]@{
        file = $File
        message = $Message
        priority_rank = $Rank
        created_at = [datetime]$Message.created_at
    })
}

$Selected = $Candidates |
    Sort-Object priority_rank, created_at |
    Select-Object -First 1

if ($null -eq $Selected) {
    return $null
}

if (-not $Peek) {
    & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
        -MessageId ([string]$Selected.message.message_id) `
        -DestinationQueue "processing" `
        -Actor "message-receiver" `
        -Details "Message claimed for processing." |
        Out-Null
}

return & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId ([string]$Selected.message.message_id)
'@

Write-NewFile ".\scripts\messaging\Receive-AIOfficeMessage.ps1" $ReceiveScript

$AckScript = @'
param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [string]$Actor = "recipient"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Queue = [string]$Message.current_queue
$Path = Join-Path `
    (Get-AIOfficeMessageQueuePath -Queue $Queue) `
    ($MessageId + ".json")

$Now = (Get-Date).ToString("o")
$Message.status = "acknowledged"
$Message.acknowledged_at = $Now
$Message.updated_at = $Now

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in (ConvertTo-AIOfficeMessageArray $Message.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "acknowledged"
    actor = $Actor
    details = "Message acknowledged."
})

$Message.history = @($History | ForEach-Object { $_ })

if ($null -ne $Message.PSObject.Properties["current_queue"]) {
    $Message.PSObject.Properties.Remove("current_queue")
}

Write-AIOfficeMessagingJson -Value $Message -Path $Path

Write-Host "Message acknowledged: $MessageId" -ForegroundColor Green
return $Message
'@

Write-NewFile ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1" $AckScript

$RouteScript = @'
param(
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Routing = Read-AIOfficeMessagingJson `
    -Path ".\config\messaging\routing-policy.json"

if ($null -eq $Routing) {
    throw "Routing policy could not be loaded."
}

$Destination = [string]$Routing.default_route

foreach ($Route in @($Routing.routes)) {
    $TypeMatches = [string]$Route.message_type -eq [string]$Message.message_type
    $TargetMatches = [string]$Route.target -eq [string]$Message.to

    if ($TypeMatches -and $TargetMatches) {
        $Destination = [string]$Route.queue
        break
    }
}

return & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
    -MessageId $MessageId `
    -DestinationQueue $Destination `
    -Actor "message-router" `
    -Details (
        "Message routed by policy to " +
        $Destination +
        "."
    )
'@

Write-NewFile ".\scripts\messaging\Route-AIOfficeMessage.ps1" $RouteScript

$ListScript = @'
param(
    [string]$Queue = "",
    [string]$From = "",
    [string]$To = "",
    [string]$MessageType = "",
    [string]$ConversationId = "",
    [string]$CorrelationId = "",
    [int]$Limit = 100
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

if (-not [string]::IsNullOrWhiteSpace($Queue)) {
    $Queues = @($Queue)
}

$Results = New-Object System.Collections.Generic.List[object]

foreach ($CurrentQueue in $Queues) {
    $Path = Get-AIOfficeMessageQueuePath -Queue $CurrentQueue

    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Filter "MSG-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Message = Read-AIOfficeMessagingJson -Path $File.FullName

        if ($null -eq $Message) {
            continue
        }

        if ($From -and [string]$Message.from -ne $From) {
            continue
        }

        if ($To -and [string]$Message.to -ne $To) {
            continue
        }

        if ($MessageType -and [string]$Message.message_type -ne $MessageType) {
            continue
        }

        if ($ConversationId -and
            [string]$Message.conversation_id -ne $ConversationId) {
            continue
        }

        if ($CorrelationId -and
            [string]$Message.correlation_id -ne $CorrelationId) {
            continue
        }

        $Results.Add([pscustomobject]@{
            queue = $CurrentQueue
            message_id = [string]$Message.message_id
            correlation_id = [string]$Message.correlation_id
            conversation_id = [string]$Message.conversation_id
            from = [string]$Message.from
            to = [string]$Message.to
            message_type = [string]$Message.message_type
            priority = [string]$Message.priority
            status = [string]$Message.status
            subject = [string]$Message.subject
            created_at = [string]$Message.created_at
        })
    }
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
'@

Write-NewFile ".\scripts\messaging\Search-AIOfficeMessages.ps1" $ListScript

$CompleteScript = @'
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
'@

Write-NewFile ".\scripts\messaging\Complete-AIOfficeMessage.ps1" $CompleteScript

$FailScript = @'
param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [Parameter(Mandatory=$true)][string]$Reason,
    [string]$Actor = "message-processor"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Queue = [string]$Message.current_queue
$Path = Join-Path `
    (Get-AIOfficeMessageQueuePath -Queue $Queue) `
    ($MessageId + ".json")

$Message.delivery_attempts = [int]$Message.delivery_attempts + 1
$Message.updated_at = (Get-Date).ToString("o")

if ($null -eq $Message.metadata) {
    $Message.metadata = [pscustomobject]@{}
}

if ($null -ne $Message.metadata.PSObject.Properties["last_error"]) {
    $Message.metadata.last_error = $Reason
}
else {
    $Message.metadata | Add-Member `
        -MemberType NoteProperty `
        -Name "last_error" `
        -Value $Reason
}

if ($null -ne $Message.PSObject.Properties["current_queue"]) {
    $Message.PSObject.Properties.Remove("current_queue")
}

Write-AIOfficeMessagingJson -Value $Message -Path $Path

return & ".\scripts\messaging\Move-AIOfficeMessage.ps1" `
    -MessageId $MessageId `
    -DestinationQueue "failed" `
    -Actor $Actor `
    -Details ("Message failed: " + $Reason)
'@

Write-NewFile ".\scripts\messaging\Fail-AIOfficeMessage.ps1" $FailScript

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Part B Queue Engine..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$Required = @(
    ".\config\messaging\queue-policy.json",
    ".\scripts\messaging\Move-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1",
    ".\scripts\messaging\Route-AIOfficeMessage.ps1",
    ".\scripts\messaging\Search-AIOfficeMessages.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1",
    ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1"
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
    Get-Content ".\config\messaging\queue-policy.json" -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] queue-policy.json" -ForegroundColor Green
}
catch {
    Write-Host "[JSON ERROR] queue-policy.json" -ForegroundColor Red
    $Errors.Add("Invalid queue policy JSON.")
}

$TestIds = New-Object System.Collections.Generic.List[string]

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Part B routing test" `
        -ConversationTopic "QUEUE-TEST" `
        -Queue "inbox" `
        -PayloadJson '{"test":"route"}'

    $TestIds.Add([string]$Message.message_id)

    & ".\scripts\messaging\Route-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id) |
        Out-Null

    $Routed = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$Message.message_id)

    if ([string]$Routed.current_queue -ne "outbox") {
        throw "Message was not routed to outbox."
    }

    Write-Host "[ROUTE OK ] Message routed to outbox." `
        -ForegroundColor Green
}
catch {
    Write-Host "[ROUTE ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Routing failed: " + $_.Exception.Message)
}

try {
    $Received = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "outbox" `
        -Recipient "bridge"

    if ($null -eq $Received -or
        [string]$Received.current_queue -ne "processing") {
        throw "Message was not claimed into processing."
    }

    & ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1" `
        -MessageId ([string]$Received.message_id) `
        -Actor "bridge" |
        Out-Null

    & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
        -MessageId ([string]$Received.message_id) `
        -Actor "bridge" |
        Out-Null

    $Completed = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$Received.message_id)

    if ([string]$Completed.current_queue -ne "processed") {
        throw "Message was not completed into processed."
    }

    Write-Host "[PROCESS OK] Receive, acknowledge, complete passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[PROCESS ER] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Processing failed: " + $_.Exception.Message)
}

try {
    $FailedMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "analytics" `
        -To "chief-of-staff" `
        -MessageType "error" `
        -Priority "urgent" `
        -Subject "Part B failure test" `
        -ConversationTopic "FAIL-TEST" `
        -Queue "processing" `
        -PayloadJson '{"test":"failure"}'

    $TestIds.Add([string]$FailedMessage.message_id)

    & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
        -MessageId ([string]$FailedMessage.message_id) `
        -Reason "Validation failure" |
        Out-Null

    $Failed = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
        -MessageId ([string]$FailedMessage.message_id)

    if ([string]$Failed.current_queue -ne "failed" -or
        [int]$Failed.delivery_attempts -ne 1) {
        throw "Failed message state was incorrect."
    }

    Write-Host "[FAIL OK   ] Failure handling passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[FAIL ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Failure handling failed: " + $_.Exception.Message)
}

try {
    $Search = @(
        & ".\scripts\messaging\Search-AIOfficeMessages.ps1" `
            -ConversationId ([string]$Message.conversation_id)
    )

    if ($Search.Count -lt 1) {
        throw "Search did not return the test message."
    }

    Write-Host "[SEARCH OK ] Search returned message(s)." `
        -ForegroundColor Green
}
catch {
    Write-Host "[SEARCH ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Search failed: " + $_.Exception.Message)
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
        " queue engine error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Part B Queue Engine checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1" $Test

$Guide = @'
# AI Office v1.1.2 Part B — Queue Engine

Part B adds durable queue movement and message lifecycle control.

## Added

- Message lookup
- Queue movement
- Policy-based routing
- Priority-aware receiving
- Message claiming
- Acknowledgement
- Completion
- Failure handling
- Delivery-attempt tracking
- Message searching
- Queue-engine validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1"
```

Expected result:

```text
All AI Office v1.1.2 Part B Queue Engine checks passed.
```

## Next

Part C adds retry scheduling, dead-letter handling, maintenance, archival, and processor controls.
'@

Write-NewFile ".\docs\AI-Office-v1.1.2-Part-B-Queue-Engine.md" $Guide

Write-Host ""
Write-Host "Validating Part B configuration..." -ForegroundColor Cyan

Get-Content ".\config\messaging\queue-policy.json" -Raw |
    ConvertFrom-Json |
    Out-Null

Write-Host "[VALID JSON] .\config\messaging\queue-policy.json" `
    -ForegroundColor Green

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.1.2-Part-B-Queue-Engine-Install.ps1"

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
Write-Host "AI Office v1.1.2 Part B installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1"'
Write-Host ""
