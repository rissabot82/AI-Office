# ============================================================
# AI Office v1.1.2 - Part A
# Messaging Foundation
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
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

$Folders = @(
    ".\config\messaging",
    ".\workspace\messages",
    ".\workspace\messages\inbox",
    ".\workspace\messages\outbox",
    ".\workspace\messages\processing",
    ".\workspace\messages\processed",
    ".\workspace\messages\failed",
    ".\workspace\messages\dead-letter",
    ".\workspace\messages\archive",
    ".\workspace\messages\history",
    ".\scripts\messaging",
    ".\docs",
    ".\Installers"
)

foreach ($Folder in $Folders) {
    Ensure-Directory -Path $Folder
}

$Now = (Get-Date).ToString("o")

$Policy = @"
{
  "schema_version": "1.0.0",
  "system": "AI Office Message Bus",
  "version": "1.1.2",
  "part": "A",
  "status": "foundation_installed",
  "default_timezone": "America/Chicago",
  "default_priority": "normal",
  "max_delivery_attempts": 3,
  "processing_timeout_seconds": 300,
  "message_retention_days": 90,
  "archive_after_days": 30,
  "allowed_priorities": [
    "low",
    "normal",
    "high",
    "urgent",
    "critical"
  ],
  "allowed_message_types": [
    "information",
    "request",
    "response",
    "execution_request",
    "execution_result",
    "approval_request",
    "approval_result",
    "handoff",
    "status",
    "error",
    "event"
  ],
  "allowed_statuses": [
    "draft",
    "queued",
    "processing",
    "delivered",
    "acknowledged",
    "completed",
    "failed",
    "dead_lettered",
    "archived"
  ],
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\messaging\messaging-policy.json" $Policy

$Schema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/message-schema.json",
  "title": "AI Office Message",
  "type": "object",
  "required": [
    "message_id",
    "correlation_id",
    "conversation_id",
    "office_id",
    "office_version",
    "from",
    "to",
    "message_type",
    "priority",
    "status",
    "created_at",
    "delivery_attempts",
    "payload",
    "history"
  ],
  "properties": {
    "message_id": {
      "type": "string",
      "pattern": "^MSG-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "correlation_id": {
      "type": "string",
      "pattern": "^COR-[A-F0-9]{12}$"
    },
    "conversation_id": {
      "type": "string",
      "pattern": "^CONV-[A-Z0-9-]+$"
    },
    "office_id": {
      "type": "string"
    },
    "office_version": {
      "type": "string"
    },
    "from": {
      "type": "string",
      "minLength": 1
    },
    "to": {
      "type": "string",
      "minLength": 1
    },
    "message_type": {
      "type": "string"
    },
    "priority": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "subject": {
      "type": "string"
    },
    "workflow_id": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    },
    "available_at": {
      "type": "string"
    },
    "expires_at": {
      "type": ["string", "null"]
    },
    "delivery_attempts": {
      "type": "integer",
      "minimum": 0
    },
    "requires_acknowledgement": {
      "type": "boolean"
    },
    "acknowledged_at": {
      "type": ["string", "null"]
    },
    "payload": {
      "type": "object"
    },
    "metadata": {
      "type": "object"
    },
    "history": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\messaging\message-schema.json" $Schema

$Routing = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.2",
  "default_route": "inbox",
  "routes": [
    {
      "message_type": "execution_request",
      "target": "bridge",
      "queue": "outbox"
    },
    {
      "message_type": "approval_request",
      "target": "chief-of-staff",
      "queue": "inbox"
    },
    {
      "message_type": "execution_result",
      "target": "chief-of-staff",
      "queue": "inbox"
    },
    {
      "message_type": "error",
      "target": "chief-of-staff",
      "queue": "failed"
    }
  ],
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\messaging\routing-policy.json" $Routing

$Index = @'
{
  "schema_version": "1.0.0",
  "updated_at": "",
  "total_messages": 0,
  "inbox_count": 0,
  "outbox_count": 0,
  "processing_count": 0,
  "processed_count": 0,
  "failed_count": 0,
  "dead_letter_count": 0,
  "archive_count": 0,
  "latest_message_id": "",
  "latest_message_at": "",
  "status": "empty"
}
'@

Write-NewFile ".\workspace\messages\message-index.json" $Index

$Template = @'
{
  "message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "correlation_id": "COR-ABCDEF123456",
  "conversation_id": "CONV-EXAMPLE",
  "office_id": "AIOFFICE-RISSABOT82-001",
  "office_version": "1.1.2",
  "from": "chief-of-staff",
  "to": "bridge",
  "message_type": "execution_request",
  "priority": "normal",
  "status": "queued",
  "subject": "Example message",
  "workflow_id": "",
  "created_at": "",
  "updated_at": "",
  "available_at": "",
  "expires_at": null,
  "delivery_attempts": 0,
  "requires_acknowledgement": true,
  "acknowledged_at": null,
  "payload": {},
  "metadata": {},
  "history": []
}
'@

Write-NewFile ".\workspace\templates\message-template.json" $Template

$Common = @'
$script:AIOfficeMessagingRoot = $null

function Get-AIOfficeMessagingRoot {
    if ($script:AIOfficeMessagingRoot) {
        return $script:AIOfficeMessagingRoot
    }

    $script:AIOfficeMessagingRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeMessagingRoot
}

function Read-AIOfficeMessagingJson {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Write-AIOfficeMessagingJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 50 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function ConvertTo-AIOfficeMessageArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function New-AIOfficeMessageId {
    $Stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $Suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return "MSG-$Stamp-$Suffix"
}

function New-AIOfficeCorrelationId {
    return "COR-" + (
        [guid]::NewGuid().ToString("N").Substring(0,12)
    ).ToUpperInvariant()
}

function New-AIOfficeConversationId {
    param([string]$Topic = "GENERAL")

    $SafeTopic = ($Topic.ToUpperInvariant() -replace "[^A-Z0-9-]", "-")
    $Stamp = (Get-Date).ToString("yyyyMMdd")
    $Suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()

    return "CONV-$SafeTopic-$Stamp-$Suffix"
}

function Get-AIOfficeMessagingPolicy {
    $Root = Get-AIOfficeMessagingRoot

    return Read-AIOfficeMessagingJson `
        -Path (Join-Path $Root "config\messaging\messaging-policy.json")
}

function Get-AIOfficeMessagingIdentity {
    $Root = Get-AIOfficeMessagingRoot
    $Path = Join-Path $Root "config\identity\office.json"

    $Identity = Read-AIOfficeMessagingJson -Path $Path

    if ($null -eq $Identity) {
        throw "AI Office identity is required. Install v1.1.1 first."
    }

    return $Identity
}

function Get-AIOfficeMessageQueuePath {
    param([Parameter(Mandatory=$true)][string]$Queue)

    $Allowed = @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )

    if ($Allowed -notcontains $Queue) {
        throw "Unsupported message queue: $Queue"
    }

    $Root = Get-AIOfficeMessagingRoot
    return Join-Path $Root ("workspace\messages\" + $Queue)
}

function Test-AIOfficeMessageShape {
    param([Parameter(Mandatory=$true)]$Message)

    $Required = @(
        "message_id",
        "correlation_id",
        "conversation_id",
        "office_id",
        "office_version",
        "from",
        "to",
        "message_type",
        "priority",
        "status",
        "created_at",
        "delivery_attempts",
        "payload",
        "history"
    )

    foreach ($Name in $Required) {
        if ($null -eq $Message.PSObject.Properties[$Name]) {
            return $false
        }
    }

    return $true
}
'@

Write-NewFile ".\scripts\messaging\AIOfficeMessaging.Common.ps1" $Common

$NewMessage = @'
param(
    [Parameter(Mandatory=$true)][string]$From,
    [Parameter(Mandatory=$true)][string]$To,
    [Parameter(Mandatory=$true)][string]$MessageType,
    [Parameter(Mandatory=$true)][string]$PayloadJson,
    [string]$Subject = "",
    [string]$Priority = "normal",
    [string]$WorkflowId = "",
    [string]$CorrelationId = "",
    [string]$ConversationId = "",
    [string]$ConversationTopic = "GENERAL",
    [string]$Queue = "outbox",
    [switch]$NoAcknowledgement
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Policy = Get-AIOfficeMessagingPolicy
$Identity = Get-AIOfficeMessagingIdentity

if (@($Policy.allowed_priorities) -notcontains $Priority) {
    throw "Unsupported priority: $Priority"
}

if (@($Policy.allowed_message_types) -notcontains $MessageType) {
    throw "Unsupported message type: $MessageType"
}

try {
    $Payload = $PayloadJson | ConvertFrom-Json
}
catch {
    throw "PayloadJson is invalid: $($_.Exception.Message)"
}

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = New-AIOfficeCorrelationId
}

if ([string]::IsNullOrWhiteSpace($ConversationId)) {
    $ConversationId = New-AIOfficeConversationId -Topic $ConversationTopic
}

$Now = (Get-Date).ToString("o")
$MessageId = New-AIOfficeMessageId

$Message = [ordered]@{
    message_id = $MessageId
    correlation_id = $CorrelationId
    conversation_id = $ConversationId
    office_id = [string]$Identity.office_id
    office_version = "1.1.2"
    from = $From
    to = $To
    message_type = $MessageType
    priority = $Priority
    status = "queued"
    subject = $Subject
    workflow_id = $WorkflowId
    created_at = $Now
    updated_at = $Now
    available_at = $Now
    expires_at = $null
    delivery_attempts = 0
    requires_acknowledgement = (-not $NoAcknowledgement)
    acknowledged_at = $null
    payload = $Payload
    metadata = [ordered]@{
        source = "AI Office Message Bus"
        queue = $Queue
    }
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $From
            details = "Message created in queue $Queue."
        }
    )
}

$QueuePath = Get-AIOfficeMessageQueuePath -Queue $Queue
$Path = Join-Path $QueuePath ($MessageId + ".json")

Write-AIOfficeMessagingJson -Value $Message -Path $Path

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" | Out-Null

Write-Host "Message created: $MessageId" -ForegroundColor Green
return [pscustomobject]$Message
'@

Write-NewFile ".\scripts\messaging\New-AIOfficeMessage.ps1" $NewMessage

$UpdateIndex = @'
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
'@

Write-NewFile ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" $UpdateIndex

$ShowStatus = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE MESSAGE BUS STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Total       : " + [string]$Index.total_messages)
Write-Host ("Inbox       : " + [string]$Index.inbox_count)
Write-Host ("Outbox      : " + [string]$Index.outbox_count)
Write-Host ("Processing  : " + [string]$Index.processing_count)
Write-Host ("Processed   : " + [string]$Index.processed_count)
Write-Host ("Failed      : " + [string]$Index.failed_count)
Write-Host ("Dead-letter : " + [string]$Index.dead_letter_count)
Write-Host ("Archive     : " + [string]$Index.archive_count)
Write-Host ("Latest      : " + [string]$Index.latest_message_id)
Write-Host ""

return $Index
'@

Write-NewFile ".\scripts\messaging\Show-AIOfficeMessageStatus.ps1" $ShowStatus

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Part A Messaging Foundation..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\messaging\messaging-policy.json",
    ".\config\messaging\message-schema.json",
    ".\config\messaging\routing-policy.json",
    ".\workspace\messages\message-index.json",
    ".\workspace\templates\message-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\messaging\AIOfficeMessaging.Common.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1",
    ".\scripts\messaging\Show-AIOfficeMessageStatus.ps1",
    ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

$TestMessageId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Subject "Part A validation message" `
        -Priority "normal" `
        -ConversationTopic "VALIDATION" `
        -Queue "outbox" `
        -PayloadJson '{"validation":true,"milestone":"1.1.2-A"}'

    $TestMessageId = [string]$Message.message_id

    if ([string]::IsNullOrWhiteSpace($TestMessageId)) {
        throw "Validation message did not contain a message ID."
    }

    . ".\scripts\messaging\AIOfficeMessaging.Common.ps1"

    if (-not (Test-AIOfficeMessageShape -Message $Message)) {
        throw "Validation message did not match the expected shape."
    }

    Write-Host "[MESSAGE OK ] $TestMessageId" -ForegroundColor Green
}
catch {
    Write-Host "[MESSAGE ERR] Message creation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Message creation failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"

    if ($null -eq $Index -or [int]$Index.outbox_count -lt 1) {
        throw "Message index did not contain the validation message."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.total_messages +
        " message(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] Message indexing failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Message indexing failed: " + $_.Exception.Message)
}

if (-not [string]::IsNullOrWhiteSpace($TestMessageId)) {
    $Path = ".\workspace\messages\outbox\$TestMessageId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }

    & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
        Out-Null
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " messaging foundation error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Part A Messaging Foundation checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1" $Test

$Guide = @'
# AI Office v1.1.2 Part A — Messaging Foundation

Part A installs the core communication contract for the AI Office Message Bus.

## Added

- Messaging policy
- Message JSON schema
- Routing policy
- Durable queue folders
- Message index
- Message template
- Common messaging library
- Message ID generation
- Correlation ID generation
- Conversation ID generation
- Message creation
- Identity integration
- Foundation validation

## Create a message

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\New-AIOfficeMessage.ps1" `
    -From "marketing" `
    -To "bridge" `
    -MessageType "execution_request" `
    -Subject "Create campaign assets" `
    -PayloadJson '{"workflow_id":"WF-1001","request":"Create assets"}'
```

## Show message status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Show-AIOfficeMessageStatus.ps1"
```

## Validate Part A

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1"
```

Expected result:

```text
All AI Office v1.1.2 Part A Messaging Foundation checks passed.
```

## Next

Part B adds queue movement, routing, acknowledgement, and message retrieval.
'@

Write-NewFile ".\docs\AI-Office-v1.1.2-Part-A-Messaging-Foundation.md" $Guide

Write-Host ""
Write-Host "Validating Part A JSON files..." -ForegroundColor Cyan

@(
    ".\config\messaging\messaging-policy.json",
    ".\config\messaging\message-schema.json",
    ".\config\messaging\routing-policy.json",
    ".\workspace\messages\message-index.json",
    ".\workspace\templates\message-template.json"
) | ForEach-Object {
    Get-Content -LiteralPath $_ -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] $_" -ForegroundColor Green
}

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.1.2-Part-A-Messaging-Foundation-Install.ps1"

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
Write-Host "AI Office v1.1.2 Part A installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1"'
Write-Host ""
