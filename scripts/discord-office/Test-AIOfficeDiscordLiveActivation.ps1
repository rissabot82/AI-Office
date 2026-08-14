param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part H Live Discord Activation and Certification..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    Get-Content ".\config\discord-office\live-activation-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\discord-office\live-activation-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid live activation policy JSON.")
}

$Scripts = @(
    ".\scripts\discord-office\Test-AIOfficeDiscordActivationReadiness.ps1",
    ".\scripts\discord-office\Enable-AIOfficeDiscordLiveOperations.ps1",
    ".\scripts\discord-office\Disable-AIOfficeDiscordLiveOperations.ps1",
    ".\scripts\discord-office\Show-AIOfficeDiscordActivationReadiness.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordLiveActivation.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Policy = Get-Content ".\config\discord-office\live-activation-policy.json" -Raw | ConvertFrom-Json

    if (-not [bool]$Policy.activation.start_worker_only_when_explicitly_requested) {
        throw "Activation policy must require explicit worker startup."
    }

    Write-Host "[SAFE ACTIVATION POLICY OK]" -ForegroundColor Green

    $ReadinessScript = Get-Content ".\scripts\discord-office\Test-AIOfficeDiscordActivationReadiness.ps1" -Raw

    foreach ($Required in @(
        "AI_OFFICE_DISCORD_BOT_TOKEN",
        "allowlist.json",
        "worker-policy.json",
        "routing-policy.json",
        "safety-policy.json",
        "Get-AIOfficeDiscordStatus.ps1"
    )) {
        if (-not $ReadinessScript.Contains($Required)) {
            throw "Activation readiness is missing requirement: $Required"
        }
    }

    Write-Host "[READINESS PIPELINE OK]" -ForegroundColor Green

    $EnableScript = Get-Content ".\scripts\discord-office\Enable-AIOfficeDiscordLiveOperations.ps1" -Raw

    if (-not $EnableScript.Contains('$StartWorker')) {
        throw "Live activation does not require explicit worker-start selection."
    }

    if (-not $EnableScript.Contains("Start-AIOfficeDiscordWorker.ps1")) {
        throw "Live activation is not wired to worker startup."
    }

    Write-Host "[LIVE WORKER CONTROL OK]" -ForegroundColor Green

    $DisableScript = Get-Content ".\scripts\discord-office\Disable-AIOfficeDiscordLiveOperations.ps1" -Raw

    if (-not $DisableScript.Contains("Stop-AIOfficeDiscordWorker.ps1")) {
        throw "Live operations disable path is not wired."
    }

    Write-Host "[DISABLE PATH OK]" -ForegroundColor Green
}
catch {
    Write-Host "[ACTIVATION ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Live Discord Activation error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part H Live Discord Activation and Certification structural checks passed." -ForegroundColor Green
Write-Host "NOTE: This certification does not start the live Discord worker." -ForegroundColor Yellow
