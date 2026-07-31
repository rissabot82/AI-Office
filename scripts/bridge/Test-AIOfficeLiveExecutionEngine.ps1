param(
    [switch]$AuthenticatedConnectionTest
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.3 Part B Live Execution Engine..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\bridge\execution-policy.json",
    ".\config\bridge\execution-record-schema.json",
    ".\workspace\templates\openclaw-execution-record-template.json"
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
    ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1",
    ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1",
    ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1",
    ".\scripts\bridge\Receive-AIOfficeBridgeWork.ps1",
    ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1"
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

try {
    $Health = & ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1"

    if (-not [bool]$Health.port_reachable) {
        Write-Host "[PORT WARN  ] Gateway port 18789 is not reachable." `
            -ForegroundColor Yellow
    }
    else {
        Write-Host "[PORT OK    ] Gateway port 18789 is reachable." `
            -ForegroundColor Green
    }
}
catch {
    Write-Host "[PORT ERR   ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Gateway port test failed: " + $_.Exception.Message)
}

if ($AuthenticatedConnectionTest) {
    try {
        $AuthHealth = & ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" `
            -Authenticated

        if (-not [bool]$AuthHealth.authenticated) {
            throw $AuthHealth.error
        }

        Write-Host (
            "[AUTH OK    ] OpenClaw " +
            [string]$AuthHealth.server_version +
            " protocol " +
            [string]$AuthHealth.protocol
        ) -ForegroundColor Green
    }
    catch {
        Write-Host "[AUTH ERR   ] $($_.Exception.Message)" `
            -ForegroundColor Red
        $Errors.Add("Authenticated connection failed: " + $_.Exception.Message)
    }
}
else {
    Write-Host (
        "[AUTH SKIP  ] Set OPENCLAW_GATEWAY_TOKEN and rerun with " +
        "-AuthenticatedConnectionTest for live authentication."
    ) -ForegroundColor Yellow
}

$MessageId = ""
$RequestId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Part B dry-run validation" `
        -ConversationTopic "BRIDGE-B-VALIDATION" `
        -Queue "outbox" `
        -PayloadJson '{"action_type":"status_check","risk_level":"low","approval_status":"not_required","prompt":"Return gateway status only."}'

    $MessageId = [string]$Message.message_id

    $Records = @(
        & ".\scripts\bridge\Receive-AIOfficeBridgeWork.ps1" `
            -Limit 1
    )

    if ($Records.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$Records[0].bridge_request_id)) {
        throw "Bridge work receiver did not create a request."
    }

    $RequestId = [string]$Records[0].bridge_request_id

    Write-Host "[QUEUE OK   ] $RequestId" -ForegroundColor Green
}
catch {
    Write-Host "[QUEUE ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Bridge queue integration failed: " + $_.Exception.Message)
}

if (-not [string]::IsNullOrWhiteSpace($RequestId)) {
    $Path = ".\workspace\bridge\requests\$RequestId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
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
        $Path = ".\workspace\messages\$Queue\$MessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
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
        " live execution engine error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.3 Part B Live Execution Engine checks passed." `
    -ForegroundColor Green
