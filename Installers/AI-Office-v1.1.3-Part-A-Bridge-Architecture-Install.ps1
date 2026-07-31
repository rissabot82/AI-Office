# ============================================================
# AI Office v1.1.3 - Part A
# OpenClaw Bridge Architecture
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.1.2 Message Bus
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\identity\office.json",
    ".\config\messaging\messaging-policy.json",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessage.ps1",
    ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.2 is required. Missing: $RequiredPath"
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
    ".\config\bridge",
    ".\workspace\bridge",
    ".\workspace\bridge\requests",
    ".\workspace\bridge\results",
    ".\workspace\bridge\artifacts",
    ".\workspace\bridge\logs",
    ".\workspace\bridge\history",
    ".\workspace\bridge\certification",
    ".\workspace\templates",
    ".\scripts\bridge",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$BridgeIdentity = @"
{
  "schema_version": "1.0.0",
  "bridge_id": "BRIDGE-OPENCLAW-001",
  "name": "AI Office OpenClaw Bridge",
  "version": "1.1.3",
  "part": "A",
  "status": "architecture_installed",
  "office_id": "AIOFFICE-RISSABOT82-001",
  "role": "execution_gateway",
  "execution_engine": "OpenClaw",
  "transport": "local_gateway",
  "gateway_url": "ws://localhost:18789",
  "gateway_host": "localhost",
  "gateway_port": 18789,
  "repository": "E:\\AI\\AI-Office",
  "mission": "Translate approved AI Office execution requests into controlled OpenClaw jobs and return auditable results through the AI Office Message Bus.",
  "created_at": "$Now",
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\bridge\bridge-identity.json" $BridgeIdentity

$BridgePolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.3",
  "part": "A",
  "enabled": true,
  "transport": {
    "type": "local_gateway",
    "protocol": "ws",
    "host": "localhost",
    "port": 18789,
    "url": "ws://localhost:18789",
    "authentication": "token",
    "token_source": "external_secret_store",
    "store_token_in_repository": false
  },
  "execution": {
    "default_timeout_seconds": 300,
    "maximum_timeout_seconds": 1800,
    "maximum_concurrent_jobs": 1,
    "require_message_bus": true,
    "require_identity": true,
    "require_approval_for_high_risk": true,
    "allow_arbitrary_shell": false,
    "allow_git_push": false,
    "allow_file_deletion": false,
    "allow_external_publish": false
  },
  "retry": {
    "enabled": true,
    "maximum_attempts": 3,
    "base_delay_seconds": 30,
    "backoff_multiplier": 2
  },
  "result_handling": {
    "capture_structured_result": true,
    "capture_artifact_manifest": true,
    "capture_execution_log": true,
    "capture_screenshots_when_requested": true,
    "store_runtime_data_outside_git": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\bridge\bridge-policy.json" $BridgePolicy

$Capabilities = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.3",
  "bridge_id": "BRIDGE-OPENCLAW-001",
  "declared_capabilities": [
    "browser",
    "camera",
    "canvas",
    "device",
    "location",
    "screen",
    "system"
  ],
  "approved_initial_capabilities": [
    "browser",
    "canvas",
    "device",
    "screen"
  ],
  "restricted_initial_capabilities": [
    "camera",
    "location",
    "system"
  ],
  "allowed_initial_commands": [
    "browser.proxy",
    "canvas.snapshot",
    "device.info",
    "device.status",
    "screen.snapshot"
  ],
  "approval_required_commands": [
    "system.run",
    "system.run.prepare",
    "system.execApprovals.set",
    "camera.snap",
    "camera.clip",
    "screen.record",
    "location.get"
  ],
  "blocked_commands": [
    "unapproved_file_delete",
    "unapproved_git_push",
    "unapproved_external_publish",
    "credential_read",
    "credential_export"
  ],
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\bridge\bridge-capabilities.json" $Capabilities

$ApprovalPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.3",
  "risk_levels": [
    "low",
    "medium",
    "high",
    "critical"
  ],
  "approval_rules": [
    {
      "risk_level": "low",
      "approval_required": false,
      "examples": [
        "read device status",
        "capture non-sensitive screen snapshot",
        "inspect browser state",
        "read approved local metadata"
      ]
    },
    {
      "risk_level": "medium",
      "approval_required": true,
      "examples": [
        "navigate browser to external service",
        "download file",
        "create local file",
        "modify non-sensitive local file"
      ]
    },
    {
      "risk_level": "high",
      "approval_required": true,
      "examples": [
        "run PowerShell",
        "submit external form",
        "publish content",
        "modify account settings",
        "upload file"
      ]
    },
    {
      "risk_level": "critical",
      "approval_required": true,
      "examples": [
        "financial transaction",
        "delete data",
        "rotate credentials",
        "change security settings",
        "push Git changes",
        "send external communication"
      ]
    }
  ],
  "default_risk_level": "high",
  "deny_when_approval_missing": true,
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\bridge\approval-policy.json" $ApprovalPolicy

$RequestSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/openclaw-bridge-request-schema.json",
  "title": "AI Office OpenClaw Bridge Request",
  "type": "object",
  "required": [
    "bridge_request_id",
    "message_id",
    "correlation_id",
    "conversation_id",
    "workflow_id",
    "requested_by",
    "target_engine",
    "action_type",
    "risk_level",
    "approval_status",
    "status",
    "created_at",
    "payload",
    "history"
  ],
  "properties": {
    "bridge_request_id": {
      "type": "string",
      "pattern": "^BRQ-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "message_id": {
      "type": "string"
    },
    "correlation_id": {
      "type": "string"
    },
    "conversation_id": {
      "type": "string"
    },
    "workflow_id": {
      "type": "string"
    },
    "requested_by": {
      "type": "string"
    },
    "target_engine": {
      "type": "string"
    },
    "action_type": {
      "type": "string"
    },
    "risk_level": {
      "type": "string"
    },
    "approval_status": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    },
    "payload": {
      "type": "object"
    },
    "history": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\bridge\bridge-request-schema.json" $RequestSchema

$ResultSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/openclaw-bridge-result-schema.json",
  "title": "AI Office OpenClaw Bridge Result",
  "type": "object",
  "required": [
    "bridge_result_id",
    "bridge_request_id",
    "message_id",
    "status",
    "started_at",
    "completed_at",
    "result",
    "artifacts",
    "history"
  ],
  "properties": {
    "bridge_result_id": {
      "type": "string"
    },
    "bridge_request_id": {
      "type": "string"
    },
    "message_id": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "started_at": {
      "type": "string"
    },
    "completed_at": {
      "type": "string"
    },
    "result": {
      "type": "object"
    },
    "artifacts": {
      "type": "array"
    },
    "history": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\bridge\bridge-result-schema.json" $ResultSchema

$Index = @'
{
  "schema_version": "1.0.0",
  "updated_at": "",
  "bridge_id": "",
  "status": "empty",
  "pending_request_count": 0,
  "completed_result_count": 0,
  "artifact_count": 0,
  "latest_request_id": "",
  "latest_result_id": "",
  "gateway_url": "",
  "gateway_reachable": false
}
'@

Write-NewFile ".\workspace\bridge\bridge-index.json" $Index

$RequestTemplate = @'
{
  "bridge_request_id": "BRQ-YYYYMMDD-HHMMSS-ABC123",
  "message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "correlation_id": "COR-ABCDEF123456",
  "conversation_id": "CONV-OPENCLAW",
  "workflow_id": "",
  "requested_by": "chief-of-staff",
  "target_engine": "OpenClaw",
  "action_type": "browser_task",
  "risk_level": "high",
  "approval_status": "pending",
  "status": "queued",
  "created_at": "",
  "updated_at": "",
  "payload": {},
  "history": []
}
'@

Write-NewFile ".\workspace\templates\openclaw-bridge-request-template.json" $RequestTemplate

$ResultTemplate = @'
{
  "bridge_result_id": "BRR-YYYYMMDD-HHMMSS-ABC123",
  "bridge_request_id": "BRQ-YYYYMMDD-HHMMSS-ABC123",
  "message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "status": "completed",
  "started_at": "",
  "completed_at": "",
  "result": {},
  "artifacts": [],
  "history": []
}
'@

Write-NewFile ".\workspace\templates\openclaw-bridge-result-template.json" $ResultTemplate

$Common = @'
$script:AIOfficeBridgeRoot = $null

function Get-AIOfficeBridgeRoot {
    if ($script:AIOfficeBridgeRoot) {
        return $script:AIOfficeBridgeRoot
    }

    $script:AIOfficeBridgeRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeBridgeRoot
}

function Read-AIOfficeBridgeJson {
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

function Write-AIOfficeBridgeJson {
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

function New-AIOfficeBridgeRequestId {
    return (
        "BRQ-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeBridgeResultId {
    return (
        "BRR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeBridgePolicy {
    $Root = Get-AIOfficeBridgeRoot

    return Read-AIOfficeBridgeJson `
        -Path (Join-Path $Root "config\bridge\bridge-policy.json")
}

function Get-AIOfficeBridgeApprovalPolicy {
    $Root = Get-AIOfficeBridgeRoot

    return Read-AIOfficeBridgeJson `
        -Path (Join-Path $Root "config\bridge\approval-policy.json")
}

function Test-AIOfficeBridgeApproval {
    param(
        [Parameter(Mandatory=$true)][string]$RiskLevel,
        [Parameter(Mandatory=$true)][string]$ApprovalStatus
    )

    $ApprovalPolicy = Get-AIOfficeBridgeApprovalPolicy

    if ($null -eq $ApprovalPolicy) {
        throw "Bridge approval policy could not be loaded."
    }

    $Rule = @(
        $ApprovalPolicy.approval_rules |
            Where-Object { [string]$_.risk_level -eq $RiskLevel }
    ) | Select-Object -First 1

    if ($null -eq $Rule) {
        return $false
    }

    if (-not [bool]$Rule.approval_required) {
        return $true
    }

    return [string]$ApprovalStatus -eq "approved"
}

function Test-AIOfficeOpenClawGatewayPort {
    param(
        [string]$HostName = "localhost",
        [int]$Port = 18789,
        [int]$TimeoutMilliseconds = 1500
    )

    $Client = New-Object System.Net.Sockets.TcpClient

    try {
        $Async = $Client.BeginConnect($HostName, $Port, $null, $null)
        $Connected = $Async.AsyncWaitHandle.WaitOne(
            $TimeoutMilliseconds,
            $false
        )

        if (-not $Connected) {
            return $false
        }

        $Client.EndConnect($Async)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $Client.Close()
    }
}
'@

Write-NewFile ".\scripts\bridge\AIOfficeBridge.Common.ps1" $Common

$NewRequest = @'
param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [Parameter(Mandatory=$true)][string]$RequestedBy,
    [Parameter(Mandatory=$true)][string]$ActionType,
    [Parameter(Mandatory=$true)][string]$PayloadJson,
    [string]$WorkflowId = "",
    [string]$CorrelationId = "",
    [string]$ConversationId = "",
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "high",
    [ValidateSet("pending","approved","rejected","not_required")]
    [string]$ApprovalStatus = "pending"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

try {
    $Payload = $PayloadJson | ConvertFrom-Json
}
catch {
    throw "PayloadJson is invalid: $($_.Exception.Message)"
}

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

if ($null -eq $Message) {
    throw "Message not found: $MessageId"
}

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = [string]$Message.correlation_id
}

if ([string]::IsNullOrWhiteSpace($ConversationId)) {
    $ConversationId = [string]$Message.conversation_id
}

$Now = (Get-Date).ToString("o")
$RequestId = New-AIOfficeBridgeRequestId

$Request = [ordered]@{
    bridge_request_id = $RequestId
    message_id = $MessageId
    correlation_id = $CorrelationId
    conversation_id = $ConversationId
    workflow_id = $WorkflowId
    requested_by = $RequestedBy
    target_engine = "OpenClaw"
    action_type = $ActionType
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = "queued"
    created_at = $Now
    updated_at = $Now
    payload = $Payload
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $RequestedBy
            details = "Bridge request created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\bridge\requests" `
    ($RequestId + ".json")

Write-AIOfficeBridgeJson -Value $Request -Path $Path

& ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
    Out-Null

Write-Host "Bridge request created: $RequestId" -ForegroundColor Green
return [pscustomobject]$Request
'@

Write-NewFile ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" $NewRequest

$ValidateRequest = @'
param(
    [Parameter(Mandatory=$true)][string]$BridgeRequestId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Path = Join-Path `
    ".\workspace\bridge\requests" `
    ($BridgeRequestId + ".json")

$Request = Read-AIOfficeBridgeJson -Path $Path

if ($null -eq $Request) {
    throw "Bridge request not found: $BridgeRequestId"
}

$ApprovalValid = Test-AIOfficeBridgeApproval `
    -RiskLevel ([string]$Request.risk_level) `
    -ApprovalStatus ([string]$Request.approval_status)

$Validation = [ordered]@{
    bridge_request_id = $BridgeRequestId
    request_exists = $true
    target_engine_valid = ([string]$Request.target_engine -eq "OpenClaw")
    status_valid = ([string]$Request.status -eq "queued")
    approval_valid = $ApprovalValid
    message_id_present = (-not [string]::IsNullOrWhiteSpace([string]$Request.message_id))
    payload_present = ($null -ne $Request.payload)
}

$Validation.valid = (
    $Validation.request_exists -and
    $Validation.target_engine_valid -and
    $Validation.status_valid -and
    $Validation.approval_valid -and
    $Validation.message_id_present -and
    $Validation.payload_present
)

return [pscustomobject]$Validation
'@

Write-NewFile ".\scripts\bridge\Test-AIOfficeBridgeRequest.ps1" $ValidateRequest

$UpdateIndex = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Identity = Read-AIOfficeBridgeJson `
    -Path ".\config\bridge\bridge-identity.json"

$Policy = Get-AIOfficeBridgePolicy

if ($null -eq $Identity -or $null -eq $Policy) {
    throw "Bridge identity or policy could not be loaded."
}

$RequestFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\requests" `
        -Filter "BRQ-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$ResultFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\results" `
        -Filter "BRR-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$ArtifactFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\artifacts" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue
)

$LatestRequest = $RequestFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$LatestResult = $ResultFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$GatewayReachable = Test-AIOfficeOpenClawGatewayPort `
    -HostName ([string]$Policy.transport.host) `
    -Port ([int]$Policy.transport.port)

$Index = [ordered]@{
    schema_version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    bridge_id = [string]$Identity.bridge_id
    status = if ($GatewayReachable) { "ready" } else { "gateway_unreachable" }
    pending_request_count = [int]$RequestFiles.Count
    completed_result_count = [int]$ResultFiles.Count
    artifact_count = [int]$ArtifactFiles.Count
    latest_request_id = if ($null -ne $LatestRequest) { $LatestRequest.BaseName } else { "" }
    latest_result_id = if ($null -ne $LatestResult) { $LatestResult.BaseName } else { "" }
    gateway_url = [string]$Policy.transport.url
    gateway_reachable = $GatewayReachable
}

Write-AIOfficeBridgeJson `
    -Value $Index `
    -Path ".\workspace\bridge\bridge-index.json"

Write-Host (
    "Bridge index updated: " +
    $Index.status +
    " | " +
    $RequestFiles.Count.ToString() +
    " request(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
'@

Write-NewFile ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" $UpdateIndex

$ShowStatus = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE OPENCLAW BRIDGE STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Bridge ID          : " + [string]$Index.bridge_id)
Write-Host ("Status             : " + [string]$Index.status)
Write-Host ("Gateway URL        : " + [string]$Index.gateway_url)
Write-Host ("Gateway reachable  : " + [string]$Index.gateway_reachable)
Write-Host ("Pending requests   : " + [string]$Index.pending_request_count)
Write-Host ("Completed results  : " + [string]$Index.completed_result_count)
Write-Host ("Artifacts          : " + [string]$Index.artifact_count)
Write-Host ("Latest request     : " + [string]$Index.latest_request_id)
Write-Host ("Latest result      : " + [string]$Index.latest_result_id)
Write-Host ""

return $Index
'@

Write-NewFile ".\scripts\bridge\Show-AIOfficeBridgeStatus.ps1" $ShowStatus

$Test = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.3 Part A Bridge Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\bridge\bridge-identity.json",
    ".\config\bridge\bridge-policy.json",
    ".\config\bridge\bridge-capabilities.json",
    ".\config\bridge\approval-policy.json",
    ".\config\bridge\bridge-request-schema.json",
    ".\config\bridge\bridge-result-schema.json",
    ".\workspace\bridge\bridge-index.json",
    ".\workspace\templates\openclaw-bridge-request-template.json",
    ".\workspace\templates\openclaw-bridge-result-template.json"
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
    ".\scripts\bridge\AIOfficeBridge.Common.ps1",
    ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1",
    ".\scripts\bridge\Test-AIOfficeBridgeRequest.ps1",
    ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1",
    ".\scripts\bridge\Show-AIOfficeBridgeStatus.ps1",
    ".\scripts\bridge\Test-AIOfficeBridgeArchitecture.ps1"
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

$MessageId = ""
$RequestId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Bridge architecture validation" `
        -ConversationTopic "BRIDGE-VALIDATION" `
        -Queue "outbox" `
        -PayloadJson '{"action":"status_check","approval_status":"approved"}'

    $MessageId = [string]$Message.message_id

    $Request = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
        -MessageId $MessageId `
        -RequestedBy "chief-of-staff" `
        -ActionType "status_check" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required" `
        -PayloadJson '{"action":"status_check","target":"OpenClaw"}'

    $RequestId = [string]$Request.bridge_request_id

    if ([string]::IsNullOrWhiteSpace($RequestId)) {
        throw "Bridge request did not contain a request ID."
    }

    Write-Host "[REQUEST OK ] $RequestId" -ForegroundColor Green
}
catch {
    Write-Host "[REQUEST ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Bridge request creation failed: " + $_.Exception.Message)
}

try {
    $Validation = & ".\scripts\bridge\Test-AIOfficeBridgeRequest.ps1" `
        -BridgeRequestId $RequestId

    if (-not [bool]$Validation.valid) {
        throw "Bridge request validation returned false."
    }

    Write-Host "[APPROVAL OK] Risk and approval validation passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[APPROVAL ER] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Approval validation failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1"

    if ($null -eq $Index -or
        [string]$Index.bridge_id -ne "BRIDGE-OPENCLAW-001") {
        throw "Bridge index did not contain expected values."
    }

    Write-Host (
        "[INDEX OK   ] Gateway reachable: " +
        [string]$Index.gateway_reachable
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Bridge index failed: " + $_.Exception.Message)
}

if (-not [string]::IsNullOrWhiteSpace($RequestId)) {
    $RequestPath = ".\workspace\bridge\requests\$RequestId.json"

    if (Test-Path -LiteralPath $RequestPath -PathType Leaf) {
        Remove-Item -LiteralPath $RequestPath -Force
    }
}

if (-not [string]::IsNullOrWhiteSpace($MessageId)) {
    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $MessagePath = ".\workspace\messages\$Queue\$MessageId.json"

        if (Test-Path -LiteralPath $MessagePath -PathType Leaf) {
            Remove-Item -LiteralPath $MessagePath -Force
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " bridge architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.3 Part A Bridge Architecture checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\bridge\Test-AIOfficeBridgeArchitecture.ps1" $Test

$Guide = @'
# AI Office v1.1.3 Part A — OpenClaw Bridge Architecture

Part A establishes the identity, governance, approval model, schemas, indexes, and request foundation for the OpenClaw Bridge.

## Added

- Bridge identity
- Gateway connection policy
- Capability allowlist
- Restricted capability policy
- Risk-based approval rules
- Bridge request schema
- Bridge result schema
- Request and result templates
- Bridge request creation
- Request validation
- Gateway port health check
- Bridge index
- Bridge status display
- Full architecture validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeBridgeArchitecture.ps1"
```

Expected result:

```text
All AI Office v1.1.3 Part A Bridge Architecture checks passed.
```

## Show bridge status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Show-AIOfficeBridgeStatus.ps1"
```

## Security rule

The OpenClaw gateway token must remain outside the repository. Part A does not read, store, or transmit the token.

## Next

Part B will add the live execution engine that consumes approved Message Bus requests and communicates with OpenClaw.
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-Part-A-Bridge-Architecture.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.3 Part A Release Notes

## Release

OpenClaw Bridge Architecture

## Added

- Formal bridge identity
- OpenClaw gateway metadata
- Bridge governance policy
- Capability allowlist
- Restricted command policy
- Risk-based approval policy
- Request and result contracts
- Bridge request creation
- Bridge request validation
- Gateway reachability check
- Bridge status index
- Validation suite

## Next

v1.1.3 Part B — Live Execution Engine
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-Part-A-Release-Notes.md" $ReleaseNotes

# Update AI Office identity to v1.1.3.
$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Get-Content -LiteralPath $IdentityPath -Raw |
        ConvertFrom-Json

    $Identity.version = "1.1.3"
    $Identity.codename = "OpenClaw Bridge"
    $Identity.execution_engine = "OpenClaw"
    $Identity.updated_at = (Get-Date).ToString("o")

    $Identity |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $IdentityPath -Encoding UTF8

    Write-Host "[UPDATED] AI Office identity version set to 1.1.3" `
        -ForegroundColor Green
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.3"
    $Version.release_name = "OpenClaw Bridge"
    $Version.status = "part_a_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.previous_version = "1.1.2"
    $Version.next_planned_milestone = "1.1.3 Part B Live Execution Engine"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to 1.1.3" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part A JSON files..." -ForegroundColor Cyan

@(
    ".\config\bridge\bridge-identity.json",
    ".\config\bridge\bridge-policy.json",
    ".\config\bridge\bridge-capabilities.json",
    ".\config\bridge\approval-policy.json",
    ".\config\bridge\bridge-request-schema.json",
    ".\config\bridge\bridge-result-schema.json",
    ".\workspace\bridge\bridge-index.json",
    ".\workspace\templates\openclaw-bridge-request-template.json",
    ".\workspace\templates\openclaw-bridge-result-template.json"
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
        "Installers\AI-Office-v1.1.3-Part-A-Bridge-Architecture-Install.ps1"

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
Write-Host "AI Office v1.1.3 Part A installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\bridge\Test-AIOfficeBridgeArchitecture.ps1"'
Write-Host ""
