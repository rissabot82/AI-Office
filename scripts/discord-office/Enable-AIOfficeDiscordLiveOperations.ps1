param(
    [switch]$StartWorker
)

$ErrorActionPreference = "Stop"

$Readiness = & "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordActivationReadiness.ps1"

if (-not [bool]$Readiness.ready) {
    Write-Host "AI Office Discord live activation is NOT ready." -ForegroundColor Red
    foreach ($Check in @($Readiness.checks)) {
        $Color = if ([bool]$Check.passed) { "Green" } else { "Red" }
        Write-Host "[$($Check.name)] $($Check.details)" -ForegroundColor $Color
    }
    throw "Discord live activation readiness checks failed."
}

Write-Host "AI Office Discord live activation readiness checks passed." -ForegroundColor Green

if ($StartWorker) {
    & "E:\AI\AI-Office\scripts\discord-office\Start-AIOfficeDiscordWorker.ps1"
    Start-Sleep -Seconds 3

    $State = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1"

    if ([string]$State.status -ne "running") {
        throw "Discord worker did not enter running state."
    }

    Write-Host "AI Office Discord worker is running." -ForegroundColor Green
}
else {
    Write-Host "Worker was not started. Re-run with -StartWorker when ready for live Discord operations." -ForegroundColor Yellow
}

return $Readiness
