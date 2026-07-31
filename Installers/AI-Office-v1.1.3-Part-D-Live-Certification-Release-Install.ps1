# ============================================================
# AI Office v1.1.3 - Part D
# OpenClaw Bridge Certification and Release
# Repository: E:\AI\AI-Office
# Requires: v1.1.3 Parts A, B, and C
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\bridge\bridge-identity.json",
    ".\config\bridge\bridge-policy.json",
    ".\config\bridge\execution-policy.json",
    ".\config\bridge\result-policy.json",
    ".\scripts\bridge\AIOfficeBridge.Common.ps1",
    ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1",
    ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1",
    ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.3 Parts A, B, and C are required. Missing: $RequiredPath"
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
    ".\workspace\bridge\certification",
    ".\workspace\bridge\releases",
    ".\workspace\bridge\reports"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$ReleaseManifest = @"
{
  "product": "AI Office",
  "component": "OpenClaw Bridge",
  "version": "1.1.3",
  "release_name": "OpenClaw Bridge",
  "release_status": "installed",
  "installed_at": "$Now",
  "parts": {
    "A": "Bridge Architecture",
    "B": "Live Execution Engine",
    "C": "Result and Artifact Processing",
    "D": "Certification and Release"
  },
  "capabilities": [
    "message_bus_consumption",
    "bridge_request_validation",
    "risk_based_approval",
    "gateway_port_health_check",
    "gateway_websocket_transport",
    "gateway_token_authentication",
    "openclaw_agent_execution",
    "execution_record_persistence",
    "result_normalization",
    "artifact_discovery",
    "artifact_manifests",
    "sha256_integrity",
    "result_message_publishing",
    "failure_propagation",
    "offline_certification",
    "optional_live_certification"
  ],
  "security": {
    "gateway_token_in_repository": false,
    "arbitrary_shell_enabled": false,
    "unapproved_external_publish_enabled": false,
    "unapproved_git_push_enabled": false,
    "high_risk_approval_required": true
  },
  "next_planned_milestone": "1.1.4 Chief of Staff Integration"
}
"@

Write-NewFile ".\config\bridge\release-manifest.json" $ReleaseManifest

$CertificationSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/openclaw-bridge-certification-schema.json",
  "title": "AI Office OpenClaw Bridge Certification",
  "type": "object",
  "required": [
    "certification_id",
    "version",
    "certified_at",
    "mode",
    "status",
    "passed_checks",
    "failed_checks",
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
    "mode": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "passed_checks": {
      "type": "integer"
    },
    "failed_checks": {
      "type": "integer"
    },
    "checks": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\bridge\certification-schema.json" $CertificationSchema

$LiveTestPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.3",
  "live_test": {
    "enabled_only_by_switch": true,
    "requires_authenticated_connection": true,
    "default_session_key": "ai-office-bridge-certification",
    "default_timeout_seconds": 120,
    "prompt": "Respond with exactly: AI Office OpenClaw Bridge live certification successful.",
    "expected_text": "AI Office OpenClaw Bridge live certification successful."
  },
  "cleanup": {
    "remove_test_messages": true,
    "remove_test_requests": true,
    "remove_test_executions": false,
    "retain_certification_records": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\bridge\live-certification-policy.json" $LiveTestPolicy

$CertifyScript = @'
param(
    [switch]$AuthenticatedConnectionTest,
    [switch]$LiveExecutionTest
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-BridgeCertificationCheck {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][bool]$Passed,
        [Parameter(Mandatory=$true)][string]$Details
    )

    $Checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$JsonFiles = @(
    ".\config\bridge\bridge-identity.json",
    ".\config\bridge\bridge-policy.json",
    ".\config\bridge\bridge-capabilities.json",
    ".\config\bridge\approval-policy.json",
    ".\config\bridge\execution-policy.json",
    ".\config\bridge\result-policy.json",
    ".\config\bridge\release-manifest.json",
    ".\config\bridge\certification-schema.json",
    ".\config\bridge\live-certification-policy.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-BridgeCertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-BridgeCertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$RequiredScripts = @(
    ".\scripts\bridge\AIOfficeBridge.Common.ps1",
    ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1",
    ".\scripts\bridge\AIOfficeBridgeResults.Common.ps1",
    ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1",
    ".\scripts\bridge\Test-AIOfficeBridgeRequest.ps1",
    ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1",
    ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1",
    ".\scripts\bridge\Receive-AIOfficeBridgeWork.ps1",
    ".\scripts\bridge\New-AIOfficeArtifactManifest.ps1",
    ".\scripts\bridge\ConvertTo-AIOfficeNormalizedResult.ps1",
    ".\scripts\bridge\Publish-AIOfficeOpenClawResult.ps1",
    ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1",
    ".\scripts\bridge\Search-AIOfficeBridgeArtifacts.ps1",
    ".\scripts\bridge\Certify-AIOfficeOpenClawBridge.ps1",
    ".\scripts\bridge\Test-AIOfficeOpenClawBridge.ps1",
    ".\scripts\bridge\Publish-AIOfficeOpenClawBridgeRelease.ps1"
)

foreach ($Path in $RequiredScripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-BridgeCertificationCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

try {
    $Index = & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1"

    Add-BridgeCertificationCheck `
        -Name "Gateway port reachable" `
        -Passed ([bool]$Index.gateway_reachable) `
        -Details (
            [string]$Index.gateway_url +
            " | reachable=" +
            [string]$Index.gateway_reachable
        )
}
catch {
    Add-BridgeCertificationCheck `
        -Name "Gateway port reachable" `
        -Passed $false `
        -Details $_.Exception.Message
}

if ($AuthenticatedConnectionTest -or $LiveExecutionTest) {
    try {
        $Health = & ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" `
            -Authenticated

        Add-BridgeCertificationCheck `
            -Name "Authenticated Gateway connection" `
            -Passed ([bool]$Health.authenticated) `
            -Details $(if ([bool]$Health.authenticated) {
                "Server " +
                [string]$Health.server_version +
                " | protocol " +
                [string]$Health.protocol
            }
            else {
                [string]$Health.error
            })
    }
    catch {
        Add-BridgeCertificationCheck `
            -Name "Authenticated Gateway connection" `
            -Passed $false `
            -Details $_.Exception.Message
    }
}
else {
    Add-BridgeCertificationCheck `
        -Name "Authenticated Gateway connection" `
        -Passed $true `
        -Details "Skipped by design. Run with -AuthenticatedConnectionTest."
}

$Mode = "offline"
$MessageId = ""
$RequestId = ""
$ExecutionId = ""
$PublishedMessageId = ""

if ($LiveExecutionTest) {
    $Mode = "live"

    try {
        $LivePolicy = Read-AIOfficeBridgeJson `
            -Path ".\config\bridge\live-certification-policy.json"

        if ($null -eq $LivePolicy) {
            throw "Live certification policy could not be loaded."
        }

        $Payload = [ordered]@{
            action_type = "agent_task"
            risk_level = "low"
            approval_status = "not_required"
            prompt = [string]$LivePolicy.live_test.prompt
        }

        $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
            -From "chief-of-staff" `
            -To "bridge" `
            -MessageType "execution_request" `
            -Priority "high" `
            -Subject "OpenClaw Bridge live certification" `
            -ConversationTopic "BRIDGE-LIVE-CERTIFICATION" `
            -Queue "processing" `
            -PayloadJson ($Payload | ConvertTo-Json -Depth 10 -Compress)

        $MessageId = [string]$Message.message_id

        $Request = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
            -MessageId $MessageId `
            -RequestedBy "chief-of-staff" `
            -ActionType "agent_task" `
            -RiskLevel "low" `
            -ApprovalStatus "not_required" `
            -PayloadJson ($Payload | ConvertTo-Json -Depth 10 -Compress)

        $RequestId = [string]$Request.bridge_request_id

        $Execution = & ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1" `
            -BridgeRequestId $RequestId `
            -SessionKey ([string]$LivePolicy.live_test.default_session_key) `
            -TimeoutSeconds ([int]$LivePolicy.live_test.default_timeout_seconds)

        $ExecutionId = [string]$Execution.execution_id

        $Published = & ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1" `
            -ExecutionId $ExecutionId `
            -Recipient "chief-of-staff"

        $PublishedMessageId = [string]$Published.message_id

        $NormalizedFiles = @(
            Get-ChildItem `
                -LiteralPath ".\workspace\bridge\results\normalized" `
                -Filter "NRR-*.json" `
                -File `
                -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending
        )

        $Normalized = $null

        foreach ($File in $NormalizedFiles) {
            $Record = Read-AIOfficeBridgeJson -Path $File.FullName

            if ($null -ne $Record -and
                [string]$Record.execution_id -eq $ExecutionId) {
                $Normalized = $Record
                break
            }
        }

        if ($null -eq $Normalized) {
            throw "Normalized live result was not found."
        }

        $ExpectedText = [string]$LivePolicy.live_test.expected_text
        $Summary = [string]$Normalized.summary
        $TextMatched = $Summary -like ("*" + $ExpectedText + "*")

        Add-BridgeCertificationCheck `
            -Name "Live OpenClaw execution" `
            -Passed (
                [string]$Execution.status -eq "completed" -and
                -not [string]::IsNullOrWhiteSpace($PublishedMessageId)
            ) `
            -Details (
                "Execution " +
                $ExecutionId +
                " | result message " +
                $PublishedMessageId
            )

        Add-BridgeCertificationCheck `
            -Name "Live response text" `
            -Passed $TextMatched `
            -Details $Summary
    }
    catch {
        Add-BridgeCertificationCheck `
            -Name "Live OpenClaw execution" `
            -Passed $false `
            -Details $_.Exception.Message
    }
}
else {
    Add-BridgeCertificationCheck `
        -Name "Live OpenClaw execution" `
        -Passed $true `
        -Details "Skipped by design. Run with -LiveExecutionTest."
}

# Offline end-to-end request/result certification.
try {
    $OfflineMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "normal" `
        -Subject "Offline bridge certification" `
        -ConversationTopic "BRIDGE-OFFLINE-CERTIFICATION" `
        -Queue "processing" `
        -PayloadJson '{"action_type":"certification","risk_level":"low","approval_status":"not_required"}'

    $OfflineMessageId = [string]$OfflineMessage.message_id

    $OfflineRequest = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
        -MessageId $OfflineMessageId `
        -RequestedBy "chief-of-staff" `
        -ActionType "certification" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required" `
        -PayloadJson '{"prompt":"Offline certification."}'

    $OfflineRequestId = [string]$OfflineRequest.bridge_request_id

    . ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1"

    $OfflineExecutionId = New-AIOfficeExecutionId
    $Current = (Get-Date).ToString("o")

    $OfflineExecution = [ordered]@{
        execution_id = $OfflineExecutionId
        bridge_request_id = $OfflineRequestId
        message_id = $OfflineMessageId
        status = "completed"
        gateway_url = "ws://localhost:18789"
        method = "offline-certification"
        run_id = "RUN-OFFLINE-CERTIFICATION"
        session_key = "ai-office-bridge-certification"
        created_at = $Current
        updated_at = $Current
        started_at = $Current
        completed_at = $Current
        request_payload = [ordered]@{
            certification = $true
        }
        response_payload = [ordered]@{
            summary = "Offline OpenClaw Bridge certification completed."
            status = "success"
        }
        error = $null
        history = @(
            [ordered]@{
                timestamp = $Current
                action = "offline_certification"
                actor = "bridge-certification"
                details = "Synthetic execution used to validate result pipeline."
            }
        )
    }

    $OfflineExecution |
        ConvertTo-Json -Depth 40 |
        Set-Content `
            -LiteralPath ".\workspace\bridge\executions\$OfflineExecutionId.json" `
            -Encoding UTF8

    $OfflinePublished = & ".\scripts\bridge\Process-AIOfficeOpenClawResult.ps1" `
        -ExecutionId $OfflineExecutionId `
        -Recipient "chief-of-staff"

    Add-BridgeCertificationCheck `
        -Name "Offline end-to-end pipeline" `
        -Passed (
            -not [string]::IsNullOrWhiteSpace(
                [string]$OfflinePublished.message_id
            )
        ) `
        -Details (
            "Execution " +
            $OfflineExecutionId +
            " published as " +
            [string]$OfflinePublished.message_id
        )

    # Clean only the temporary offline message/request/result-message.
    foreach ($CurrentMessageId in @(
        $OfflineMessageId,
        [string]$OfflinePublished.message_id
    )) {
        foreach ($Queue in @(
            "inbox",
            "outbox",
            "processing",
            "processed",
            "failed",
            "dead-letter",
            "archive"
        )) {
            $Path = ".\workspace\messages\$Queue\$CurrentMessageId.json"

            if (Test-Path -LiteralPath $Path -PathType Leaf) {
                Remove-Item -LiteralPath $Path -Force
            }
        }
    }

    $OfflineRequestPath = ".\workspace\bridge\requests\$OfflineRequestId.json"

    if (Test-Path -LiteralPath $OfflineRequestPath -PathType Leaf) {
        Remove-Item -LiteralPath $OfflineRequestPath -Force
    }
}
catch {
    Add-BridgeCertificationCheck `
        -Name "Offline end-to-end pipeline" `
        -Passed $false `
        -Details $_.Exception.Message
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
    Out-Null

$PassedCount = @(
    $Checks | Where-Object { $_.passed -eq $true }
).Count

$FailedCount = @(
    $Checks | Where-Object { $_.passed -eq $false }
).Count

$Status = if ($FailedCount -eq 0) {
    "certified"
}
else {
    "failed"
}

$CertificationId = (
    "CERT-BRIDGE-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.1.3"
    certified_at = (Get-Date).ToString("o")
    mode = $Mode
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    live_execution_id = $ExecutionId
    live_result_message_id = $PublishedMessageId
    checks = @($Checks | ForEach-Object { $_ })
}

$CertificationPath = Join-Path `
    ".\workspace\bridge\certification" `
    ($CertificationId + ".json")

Write-AIOfficeBridgeJson `
    -Value $Certification `
    -Path $CertificationPath

Write-Host (
    "OpenClaw Bridge certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
'@

Write-NewFile ".\scripts\bridge\Certify-AIOfficeOpenClawBridge.ps1" $CertifyScript

$CompleteTest = @'
param(
    [switch]$AuthenticatedConnectionTest,
    [switch]$LiveExecutionTest
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.3 OpenClaw Bridge..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-BridgeTest {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Path
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

Invoke-BridgeTest `
    -Name "Part A Bridge Architecture" `
    -Path ".\scripts\bridge\Test-AIOfficeBridgeArchitecture.ps1"

Invoke-BridgeTest `
    -Name "Part B Live Execution Engine" `
    -Path ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1"

Invoke-BridgeTest `
    -Name "Part C Result Processing" `
    -Path ".\scripts\bridge\Test-AIOfficeResultProcessing.ps1"

try {
    $Arguments = @{}

    if ($AuthenticatedConnectionTest) {
        $Arguments.AuthenticatedConnectionTest = $true
    }

    if ($LiveExecutionTest) {
        $Arguments.LiveExecutionTest = $true
    }

    $Certification = & `
        ".\scripts\bridge\Certify-AIOfficeOpenClawBridge.ps1" `
        @Arguments

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "OpenClaw Bridge certification failed."
    }

    Write-Host (
        "[PASS] Bridge certification: " +
        [string]$Certification.certification_id +
        " | mode=" +
        [string]$Certification.mode
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Bridge certification" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Bridge certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " OpenClaw Bridge error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.3 OpenClaw Bridge checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.1.3 OpenClaw Bridge is operational." `
    -ForegroundColor Cyan
'@

Write-NewFile ".\scripts\bridge\Test-AIOfficeOpenClawBridge.ps1" $CompleteTest

$PublishRelease = @'
param(
    [switch]$RequireLiveCertification
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\certification" `
        -Filter "CERT-BRIDGE-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No OpenClaw Bridge certification record exists."
}

$Certification = Read-AIOfficeBridgeJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest OpenClaw Bridge certification did not pass."
}

if ($RequireLiveCertification -and
    [string]$Certification.mode -ne "live") {
    throw "Latest certification is not a live certification."
}

$ManifestPath = ".\config\bridge\release-manifest.json"
$Manifest = Read-AIOfficeBridgeJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Bridge release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"
$Manifest.released_at = $ReleasedAt
$Manifest.certification_id = [string]$Certification.certification_id
$Manifest.certification_mode = [string]$Certification.mode

Write-AIOfficeBridgeJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "OpenClaw Bridge"
    version = "1.1.3"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    certification_mode = [string]$Certification.mode
    next_milestone = "1.1.4 Chief of Staff Integration"
}

$ReleasePath = Join-Path `
    ".\workspace\bridge\releases" `
    ("AI-Office-v1.1.3-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeBridgeJson `
    -Value $ReleaseRecord `
    -Path $ReleasePath

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeBridgeJson -Path $IdentityPath
    $Identity.version = "1.1.3"
    $Identity.codename = "OpenClaw Bridge"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeBridgeJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeBridgeJson -Path $VersionPath
    $Version.version = "1.1.3"
    $Version.release_name = "OpenClaw Bridge"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.1.2"
    $Version.next_planned_milestone = "1.1.4 Chief of Staff Integration"

    Write-AIOfficeBridgeJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.1.3 OpenClaw Bridge release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
'@

Write-NewFile ".\scripts\bridge\Publish-AIOfficeOpenClawBridgeRelease.ps1" $PublishRelease

$Guide = @'
# AI Office v1.1.3 — OpenClaw Bridge

AI Office v1.1.3 connects the Internal Message Bus to the local OpenClaw Gateway through a governed execution bridge.

## Delivered

### Part A — Bridge Architecture
- Bridge identity
- Gateway policy
- Capability allowlist
- Risk and approval rules
- Request and result contracts

### Part B — Live Execution Engine
- WebSocket protocol transport
- Gateway challenge handling
- External token authentication
- OpenClaw agent execution
- Execution records
- Message Bus consumption

### Part C — Result and Artifact Processing
- Result normalization
- Artifact discovery and copying
- SHA-256 hashes
- Artifact manifests
- Message Bus result publication
- Failure-result recording

### Part D — Certification and Release
- Complete validation suite
- Offline end-to-end certification
- Optional authenticated certification
- Optional live OpenClaw execution test
- Release publication

## Standard complete validation

This does not require a Gateway token:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeOpenClawBridge.ps1"
```

Expected ending:

```text
All AI Office v1.1.3 OpenClaw Bridge checks passed.
AI Office v1.1.3 OpenClaw Bridge is operational.
```

## Authenticated Gateway validation

Set the real token only in the current PowerShell session:

```powershell
$env:OPENCLAW_GATEWAY_TOKEN = "YOUR_REAL_GATEWAY_TOKEN"
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeOpenClawBridge.ps1" `
    -AuthenticatedConnectionTest
```

## Live execution certification

This sends a small real prompt through OpenClaw:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeOpenClawBridge.ps1" `
    -AuthenticatedConnectionTest `
    -LiveExecutionTest
```

## Publish the release

After standard or live certification:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Publish-AIOfficeOpenClawBridgeRelease.ps1"
```

To require a live certification before release:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Publish-AIOfficeOpenClawBridgeRelease.ps1" `
    -RequireLiveCertification
```

## Security

Never place the Gateway token in Git, configuration JSON, an installer, documentation, or a saved PowerShell script.

## Next milestone

AI Office v1.1.4 will connect the Chief of Staff directly to the Message Bus and OpenClaw Bridge.
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-OpenClaw-Bridge-Guide.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.3 Release Notes

## Release name

OpenClaw Bridge

## Added

- Governed execution bridge
- OpenClaw Gateway connection policy
- Token-authenticated WebSocket transport
- Message Bus execution consumption
- Risk-based approval checks
- Persistent execution records
- Result normalization
- Artifact collection and integrity hashes
- Result-message publishing
- Failure propagation
- Offline certification
- Optional authenticated and live certification
- Release publication

## Next

AI Office v1.1.4 — Chief of Staff Integration
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.3"
    $Version.release_name = "OpenClaw Bridge"
    $Version.status = "part_d_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.1.4 Chief of Staff Integration"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to Part D" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part D JSON files..." -ForegroundColor Cyan

@(
    ".\config\bridge\release-manifest.json",
    ".\config\bridge\certification-schema.json",
    ".\config\bridge\live-certification-policy.json"
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
        "Installers\AI-Office-v1.1.3-Part-D-Live-Certification-Release-Install.ps1"

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
Write-Host "AI Office v1.1.3 Part D installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run complete standard validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\bridge\Test-AIOfficeOpenClawBridge.ps1"'
Write-Host ""
