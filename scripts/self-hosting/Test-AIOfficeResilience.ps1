param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing Self-Hosted AI Office Part G Resilience, Failover and Resource Management..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\self-hosting\resilience-policy.json",
    ".\config\self-hosting\resource-snapshot-schema.json",
    ".\config\self-hosting\failover-event-schema.json",
    ".\config\self-hosting\recovery-record-schema.json",
    ".\workspace\templates\self-hosting-resource-snapshot-template.json",
    ".\workspace\templates\self-hosting-failover-event-template.json",
    ".\workspace\templates\self-hosting-recovery-record-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\self-hosting\AIOfficeResilience.Common.ps1",
    ".\scripts\self-hosting\Get-AIOfficeResourceSnapshot.ps1",
    ".\scripts\self-hosting\Test-AIOfficeSelfHostingServiceHealth.ps1",
    ".\scripts\self-hosting\New-AIOfficeFailoverEvent.ps1",
    ".\scripts\self-hosting\Invoke-AIOfficeSelfHostingRecovery.ps1",
    ".\scripts\self-hosting\Get-AIOfficeResilienceStatus.ps1",
    ".\scripts\self-hosting\Test-AIOfficeResilience.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Snapshot = & ".\scripts\self-hosting\Get-AIOfficeResourceSnapshot.ps1"

    if ([double]$Snapshot.memory_total_gb -le 0) {
        throw "System memory inventory failed."
    }

    if ([double]$Snapshot.ai_drive_free_gb -le 0) {
        throw "AI drive free-space inventory failed."
    }

    Write-Host "[RESOURCE OK] RAM=$($Snapshot.memory_total_gb) GB | E free=$($Snapshot.ai_drive_free_gb) GB" -ForegroundColor Green

    $Health = & ".\scripts\self-hosting\Test-AIOfficeSelfHostingServiceHealth.ps1"

    if (-not [bool]$Health.ollama) {
        throw "Ollama is not reachable."
    }

    if (-not [bool]$Health.openclaw_gateway) {
        throw "OpenClaw Gateway is not reachable."
    }

    if (-not [bool]$Health.dashboard) {
        throw "AI Office Dashboard is not reachable."
    }

    Write-Host "[SERVICE HEALTH OK] All required services reachable." -ForegroundColor Green

    $Failover = & ".\scripts\self-hosting\New-AIOfficeFailoverEvent.ps1" `
        -SourceProvider "ollama" `
        -TargetProvider "openclaw" `
        -Reason "Certification failover simulation."

    if ([string]$Failover.status -ne "completed") {
        throw "Failover event creation failed."
    }

    Write-Host "[FAILOVER OK] $($Failover.failover_event_id)" -ForegroundColor Green

    $Recovery = & ".\scripts\self-hosting\Invoke-AIOfficeSelfHostingRecovery.ps1" `
        -RecoverOllama `
        -RecoverDashboard

    if (@($Recovery | Where-Object { [string]$_.status -eq "failed" }).Count -gt 0) {
        throw "One or more recovery checks failed."
    }

    Write-Host "[RECOVERY OK] Runtime and dashboard recovery checks passed." -ForegroundColor Green
}
catch {
    Write-Host "[RESILIENCE ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Resilience, Failover and Resource Management error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All Self-Hosted AI Office Part G Resilience, Failover and Resource Management checks passed." -ForegroundColor Green
