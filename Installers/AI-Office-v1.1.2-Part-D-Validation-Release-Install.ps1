# ============================================================
# AI Office v1.1.2 - Part D
# Validation, Release, and End-to-End Certification
# Repository: E:\AI\AI-Office
# Requires: v1.1.2 Parts A, B, and C
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\scripts\messaging\AIOfficeMessaging.Common.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessage.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Retry-AIOfficeMessage.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.2 Parts A, B, and C are required. Missing: $RequiredPath"
    }
}

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

@(
    ".\workspace\messages\samples",
    ".\workspace\messages\certification",
    ".\workspace\messages\releases"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$ReleaseManifest = @"
{
  "product": "AI Office",
  "component": "Internal Message Bus",
  "version": "1.1.2",
  "release_name": "Internal Message Bus",
  "release_status": "installed",
  "installed_at": "$Now",
  "parts": {
    "A": "Messaging Foundation",
    "B": "Queue Engine",
    "C": "Processing Engine",
    "D": "Validation and Release"
  },
  "capabilities": [
    "durable_message_queues",
    "message_ids",
    "correlation_ids",
    "conversation_ids",
    "identity_envelopes",
    "priority_routing",
    "acknowledgements",
    "delivery_attempt_tracking",
    "retry_scheduling",
    "exponential_backoff",
    "dead_letter_queue",
    "dead_letter_recovery",
    "message_search",
    "batch_processing",
    "queue_maintenance",
    "archival",
    "audit_history"
  ],
  "next_planned_milestone": "1.1.3 OpenClaw Bridge"
}
"@

Write-NewFile ".\config\messaging\release-manifest.json" $ReleaseManifest

$SampleConversation = @'
{
  "sample_name": "OpenClaw execution request lifecycle",
  "version": "1.1.2",
  "conversation_id": "CONV-OPENCLAW-BRIDGE-SAMPLE",
  "messages": [
    {
      "sequence": 1,
      "from": "chief-of-staff",
      "to": "marketing",
      "message_type": "request",
      "subject": "Prepare an Elite Auto Sales campaign workflow"
    },
    {
      "sequence": 2,
      "from": "marketing",
      "to": "bridge",
      "message_type": "execution_request",
      "subject": "Open the approved advertising platform workflow"
    },
    {
      "sequence": 3,
      "from": "bridge",
      "to": "openclaw",
      "message_type": "execution_request",
      "subject": "Execute approved browser task"
    },
    {
      "sequence": 4,
      "from": "openclaw",
      "to": "bridge",
      "message_type": "execution_result",
      "subject": "Browser task completed"
    },
    {
      "sequence": 5,
      "from": "bridge",
      "to": "chief-of-staff",
      "message_type": "status",
      "subject": "Execution result recorded"
    }
  ]
}
'@

Write-NewFile ".\workspace\messages\samples\openclaw-execution-conversation.json" $SampleConversation

$CertificationSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/message-bus-certification-schema.json",
  "title": "AI Office Message Bus Certification",
  "type": "object",
  "required": [
    "certification_id",
    "version",
    "certified_at",
    "status",
    "checks"
  ],
  "properties": {
    "certification_id": {
      "type": "string"
    },
    "version": {
      "type": "string"
    },
    "certified_at": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "checks": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\messaging\certification-schema.json" $CertificationSchema

$ConversationScript = @'
param(
    [string]$WorkflowId = "WF-SAMPLE-OPENCLAW",
    [switch]$KeepMessages
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$ConversationId = New-AIOfficeConversationId -Topic "OPENCLAW-BRIDGE"
$CorrelationId = New-AIOfficeCorrelationId

$Messages = New-Object System.Collections.Generic.List[object]

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "request" `
        -Priority "high" `
        -Subject "Prepare approved campaign workflow" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "inbox" `
        -PayloadJson '{"store":"Elite Auto Sales","request":"Prepare campaign workflow"}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Submit approved browser execution request" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "outbox" `
        -PayloadJson '{"execution_engine":"OpenClaw","action":"browser_task","approval_status":"approved"}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "bridge" `
        -To "openclaw" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Execute approved task" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "outbox" `
        -PayloadJson '{"action":"browser_task","mode":"approved_execution"}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "openclaw" `
        -To "bridge" `
        -MessageType "execution_result" `
        -Priority "normal" `
        -Subject "Execution completed" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "inbox" `
        -PayloadJson '{"result":"success","artifact_count":1}')
)

$Messages.Add(
    (& ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "bridge" `
        -To "chief-of-staff" `
        -MessageType "status" `
        -Priority "normal" `
        -Subject "OpenClaw execution recorded" `
        -WorkflowId $WorkflowId `
        -CorrelationId $CorrelationId `
        -ConversationId $ConversationId `
        -Queue "inbox" `
        -PayloadJson '{"status":"completed","execution_engine":"OpenClaw"}')
)

$Result = [ordered]@{
    conversation_id = $ConversationId
    correlation_id = $CorrelationId
    message_count = $Messages.Count
    message_ids = @($Messages | ForEach-Object { [string]$_.message_id })
}

if (-not $KeepMessages) {
    foreach ($Message in $Messages) {
        foreach ($Queue in @(
            "inbox",
            "outbox",
            "processing",
            "processed",
            "failed",
            "dead-letter",
            "archive"
        )) {
            $Path = Join-Path `
                ".\workspace\messages\$Queue" `
                ([string]$Message.message_id + ".json")

            if (Test-Path -LiteralPath $Path -PathType Leaf) {
                Remove-Item -LiteralPath $Path -Force
            }
        }
    }

    & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
        Out-Null
}

return [pscustomobject]$Result
'@

Write-NewFile ".\scripts\messaging\New-AIOfficeSampleConversation.ps1" $ConversationScript

$CertificationScript = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-CertificationCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $Checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$RequiredJson = @(
    ".\config\messaging\messaging-policy.json",
    ".\config\messaging\message-schema.json",
    ".\config\messaging\routing-policy.json",
    ".\config\messaging\queue-policy.json",
    ".\config\messaging\processing-policy.json",
    ".\config\messaging\release-manifest.json",
    ".\config\messaging\certification-schema.json"
)

foreach ($Path in $RequiredJson) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-CertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-CertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$RequiredScripts = @(
    ".\scripts\messaging\AIOfficeMessaging.Common.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1",
    ".\scripts\messaging\Route-AIOfficeMessage.ps1",
    ".\scripts\messaging\Search-AIOfficeMessages.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1",
    ".\scripts\messaging\Retry-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessageToDeadLetter.ps1",
    ".\scripts\messaging\Recover-AIOfficeDeadLetterMessage.ps1",
    ".\scripts\messaging\Archive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1",
    ".\scripts\messaging\Retry-AIOfficeFailedMessages.ps1",
    ".\scripts\messaging\New-AIOfficeSampleConversation.ps1",
    ".\scripts\messaging\Certify-AIOfficeMessageBus.ps1",
    ".\scripts\messaging\Test-AIOfficeMessageBus.ps1"
)

foreach ($Path in $RequiredScripts) {
    Add-CertificationCheck `
        -Name ("Script exists: " + $Path) `
        -Passed (Test-Path -LiteralPath $Path -PathType Leaf) `
        -Details $(if (Test-Path -LiteralPath $Path -PathType Leaf) {
            "Found."
        }
        else {
            "Missing."
        })
}

$IdentityPath = ".\config\identity\office.json"

Add-CertificationCheck `
    -Name "Identity integration" `
    -Passed (Test-Path -LiteralPath $IdentityPath -PathType Leaf) `
    -Details "Identity System v1.1.1 is present."

$QueueFolders = @(
    "inbox",
    "outbox",
    "processing",
    "processed",
    "failed",
    "dead-letter",
    "archive"
)

foreach ($Queue in $QueueFolders) {
    $QueuePath = Get-AIOfficeMessageQueuePath -Queue $Queue

    Add-CertificationCheck `
        -Name ("Queue exists: " + $Queue) `
        -Passed (Test-Path -LiteralPath $QueuePath -PathType Container) `
        -Details $QueuePath
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -eq $false }).Count

$Status = if ($FailedCount -eq 0) {
    "certified"
}
else {
    "failed"
}

$Certification = [ordered]@{
    certification_id = (
        "CERT-MSG-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    version = "1.1.2"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\messages\certification" `
    ([string]$Certification.certification_id + ".json")

Write-AIOfficeMessagingJson -Value $Certification -Path $Path

Write-Host (
    "Message Bus certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
'@

Write-NewFile ".\scripts\messaging\Certify-AIOfficeMessageBus.ps1" $CertificationScript

$FullTest = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.2 Internal Message Bus..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-TestScript {
    param(
        [string]$Name,
        [string]$Path
    )

    try {
        & $Path

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "$Name returned exit code $LASTEXITCODE."
        }

        Write-Host ("[PASS] " + $Name) -ForegroundColor Green
    }
    catch {
        Write-Host ("[FAIL] " + $Name) -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $Errors.Add($Name + ": " + $_.Exception.Message)
    }
}

Invoke-TestScript `
    -Name "Part A Messaging Foundation" `
    -Path ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1"

Invoke-TestScript `
    -Name "Part B Queue Engine" `
    -Path ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1"

Invoke-TestScript `
    -Name "Part C Processing Engine" `
    -Path ".\scripts\messaging\Test-AIOfficeProcessingEngine.ps1"

try {
    . ".\scripts\messaging\AIOfficeMessaging.Common.ps1"

    $Conversation = & ".\scripts\messaging\New-AIOfficeSampleConversation.ps1"

    if ($null -eq $Conversation -or
        [int]$Conversation.message_count -ne 5 -or
        [string]::IsNullOrWhiteSpace([string]$Conversation.conversation_id) -or
        [string]::IsNullOrWhiteSpace([string]$Conversation.correlation_id)) {
        throw "Sample conversation did not contain expected values."
    }

    Write-Host (
        "[PASS] End-to-end conversation: " +
        [string]$Conversation.conversation_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] End-to-end conversation" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("End-to-end conversation: " + $_.Exception.Message)
}

try {
    $Certification = & ".\scripts\messaging\Certify-AIOfficeMessageBus.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Message Bus certification failed."
    }

    Write-Host (
        "[PASS] Certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Certification" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Certification: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"

    if ($null -eq $Index) {
        throw "Message index was not returned."
    }

    Write-Host (
        "[PASS] Final index: " +
        [string]$Index.total_messages +
        " message(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Final message index" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Final index: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " complete Message Bus error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.2 Internal Message Bus checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.1.2 Message Bus is operational." `
    -ForegroundColor Cyan
'@

Write-NewFile ".\scripts\messaging\Test-AIOfficeMessageBus.ps1" $FullTest

$PublishScript = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$ManifestPath = ".\config\messaging\release-manifest.json"
$Manifest = Read-AIOfficeMessagingJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Message Bus release manifest could not be loaded."
}

$Manifest.release_status = "released"
$Manifest.released_at = (Get-Date).ToString("o")

Write-AIOfficeMessagingJson -Value $Manifest -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Internal Message Bus"
    version = "1.1.2"
    released_at = (Get-Date).ToString("o")
    status = "released"
    next_milestone = "1.1.3 OpenClaw Bridge"
}

$Path = Join-Path `
    ".\workspace\messages\releases" `
    ("AI-Office-v1.1.2-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeMessagingJson -Value $ReleaseRecord -Path $Path

Write-Host "AI Office v1.1.2 release recorded." -ForegroundColor Green
return [pscustomobject]$ReleaseRecord
'@

Write-NewFile ".\scripts\messaging\Publish-AIOfficeMessageBusRelease.ps1" $PublishScript

$Guide = @'
# AI Office v1.1.2 — Internal Message Bus

AI Office v1.1.2 introduces a complete local message bus for communication between the Chief of Staff, departments, the future OpenClaw Bridge, and other execution engines.

## Core capabilities

- Durable inbox and outbox queues
- Processing, processed, failed, dead-letter, and archive queues
- Message IDs
- Correlation IDs
- Conversation IDs
- Identity integration
- Message priorities
- Routing policy
- Acknowledgements
- Delivery-attempt tracking
- Retry scheduling
- Exponential backoff
- Dead-letter handling
- Dead-letter recovery
- Batch processing
- Queue maintenance
- Search
- Archival
- Full audit history
- End-to-end certification

## Complete validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Test-AIOfficeMessageBus.ps1"
```

Expected result:

```text
All AI Office v1.1.2 Internal Message Bus checks passed.
AI Office v1.1.2 Message Bus is operational.
```

## Create a message

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\New-AIOfficeMessage.ps1" `
    -From "marketing" `
    -To "bridge" `
    -MessageType "execution_request" `
    -Subject "Execute approved browser task" `
    -Priority "high" `
    -ConversationTopic "OPENCLAW" `
    -PayloadJson '{"action":"browser_task","approval_status":"approved"}'
```

## Show queue status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Show-AIOfficeMessageStatus.ps1"
```

## Publish release record

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Publish-AIOfficeMessageBusRelease.ps1"
```

## Next milestone

AI Office v1.1.3 will build the OpenClaw Bridge on top of the Message Bus.
'@

Write-NewFile ".\docs\AI-Office-v1.1.2-Message-Bus-Guide.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.2 Release Notes

## Release name

Internal Message Bus

## Delivered

### Part A — Messaging Foundation
- Message policy
- Message schema
- Identity integration
- Queue structure
- Message creation
- Indexing

### Part B — Queue Engine
- Routing
- Receiving
- Queue movement
- Acknowledgement
- Completion
- Failure handling
- Search

### Part C — Processing Engine
- Retry scheduling
- Exponential backoff
- Dead-letter queue
- Recovery
- Batch processing
- Maintenance
- Archival

### Part D — Validation and Release
- Sample OpenClaw conversation
- End-to-end test
- Certification
- Release manifest
- Full documentation

## Next

AI Office v1.1.3 — OpenClaw Bridge
'@

Write-NewFile ".\docs\AI-Office-v1.1.2-Release-Notes.md" $ReleaseNotes

# Update Identity System to reflect the new platform version.
$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Get-Content -LiteralPath $IdentityPath -Raw |
        ConvertFrom-Json

    $Identity.version = "1.1.2"
    $Identity.codename = "Message Bus"
    $Identity.updated_at = (Get-Date).ToString("o")

    $Identity |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $IdentityPath -Encoding UTF8

    Write-Host "[UPDATED] AI Office identity version set to 1.1.2" `
        -ForegroundColor Green
}

$IdentityVersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $IdentityVersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $IdentityVersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.2"
    $Version.release_name = "Internal Message Bus"
    $Version.status = "installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.previous_version = "1.1.1"
    $Version.next_planned_milestone = "1.1.3 OpenClaw Bridge"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $IdentityVersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to 1.1.2" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part D JSON files..." -ForegroundColor Cyan

@(
    ".\config\messaging\release-manifest.json",
    ".\config\messaging\certification-schema.json",
    ".\workspace\messages\samples\openclaw-execution-conversation.json"
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
        "Installers\AI-Office-v1.1.2-Part-D-Validation-Release-Install.ps1"

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
Write-Host "AI Office v1.1.2 Part D installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run complete validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\messaging\Test-AIOfficeMessageBus.ps1"'
Write-Host ""
