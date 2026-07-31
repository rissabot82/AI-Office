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
