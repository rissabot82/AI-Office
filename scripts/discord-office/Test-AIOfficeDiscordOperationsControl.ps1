param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part F Discord Operations and Control..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    Get-Content ".\config\discord-office\operations-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\discord-office\operations-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid operations policy JSON.")
}

$Scripts = @(
    ".\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1",
    ".\scripts\discord-office\Restart-AIOfficeDiscordWorker.ps1",
    ".\scripts\discord-office\Show-AIOfficeDiscordOperations.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordOperationsCommand.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordOperationsControl.ps1"
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
    $Worker = & ".\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1"

    if ([string]::IsNullOrWhiteSpace([string]$Worker.status)) {
        throw "Worker state cannot be read."
    }

    Write-Host "[WORKER STATE OK] $($Worker.status)" -ForegroundColor Green

    $OpsCommand = & ".\scripts\discord-office\Invoke-AIOfficeDiscordOperationsCommand.ps1" `
        -CommandText "/ops"

    if (-not [bool]$OpsCommand.handled) {
        throw "/ops command was not handled."
    }

    if (-not ([string]$OpsCommand.response).Contains("AI Office operations")) {
        throw "/ops response is invalid."
    }

    Write-Host "[OPS COMMAND OK]" -ForegroundColor Green

    $WorkerCommand = & ".\scripts\discord-office\Invoke-AIOfficeDiscordOperationsCommand.ps1" `
        -CommandText "/worker"

    if (-not [bool]$WorkerCommand.handled) {
        throw "/worker command was not handled."
    }

    Write-Host "[WORKER COMMAND OK]" -ForegroundColor Green

    $StatusScript = Get-Content ".\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1" -Raw

    foreach ($Required in @(
        "Get-AIOfficeDiscordWorkerState.ps1",
        "Get-AIOfficeDiscordStatus.ps1",
        "Test-AIOfficeSelfHostingServiceHealth.ps1"
    )) {
        if (-not $StatusScript.Contains($Required)) {
            throw "Operations status is missing integration: $Required"
        }
    }

    Write-Host "[HEALTH INTEGRATION OK] Discord + worker + self-hosting wired." -ForegroundColor Green
}
catch {
    Write-Host "[OPERATIONS ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Discord Operations and Control error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part F Discord Operations and Control checks passed." -ForegroundColor Green
