param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part E Discord Worker Service..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($Json in @(
    ".\config\discord-office\worker-policy.json",
    ".\workspace\discord-office\state\worker-state.json"
)) {
    try {
        Get-Content $Json -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $Json" -ForegroundColor Green
    }
    catch {
        $Errors.Add("Invalid JSON: $Json")
    }
}

$Scripts = @(
    ".\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1",
    ".\scripts\discord-office\Start-AIOfficeDiscordWorker.ps1",
    ".\scripts\discord-office\Stop-AIOfficeDiscordWorker.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordWorker.ps1",
    ".\scripts\discord-office\Install-AIOfficeDiscordWorkerStartup.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordWorker.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Policy = Get-Content ".\config\discord-office\worker-policy.json" -Raw | ConvertFrom-Json

    if ([int]$Policy.worker.poll_interval_seconds -lt 1) {
        throw "Worker polling interval is invalid."
    }

    if ([int]$Policy.worker.max_messages_per_cycle -lt 1) {
        throw "Worker message limit is invalid."
    }

    Write-Host "[WORKER POLICY OK] Poll=$($Policy.worker.poll_interval_seconds)s | Batch=$($Policy.worker.max_messages_per_cycle)" -ForegroundColor Green

    $State = & ".\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1"

    if ([string]::IsNullOrWhiteSpace([string]$State.status)) {
        throw "Worker state is invalid."
    }

    Write-Host "[WORKER STATE OK] status=$($State.status)" -ForegroundColor Green

    $Runtime = Get-Content ".\scripts\discord-office\Invoke-AIOfficeDiscordWorker.ps1" -Raw

    foreach ($Required in @(
        "Invoke-AIOfficeDiscordInboundMessage.ps1",
        "Invoke-AIOfficeDiscordApi",
        "allowed_channel_ids",
        "last_message_id"
    )) {
        if (-not $Runtime.Contains($Required)) {
            throw "Worker runtime is missing required integration: $Required"
        }
    }

    Write-Host "[PIPELINE OK] Discord API -> intake -> routing -> conversation pipeline wired." -ForegroundColor Green
}
catch {
    Write-Host "[WORKER ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Discord Worker Service error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part E Discord Worker Service checks passed." -ForegroundColor Green
