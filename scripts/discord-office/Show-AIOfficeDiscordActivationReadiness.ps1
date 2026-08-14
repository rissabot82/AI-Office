param()

$ErrorActionPreference = "Stop"

$Readiness = & "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordActivationReadiness.ps1"

Write-Host ""
Write-Host "AI Office Discord Live Activation Readiness" -ForegroundColor Cyan
Write-Host "-------------------------------------------"

foreach ($Check in @($Readiness.checks)) {
    $Label = if ([bool]$Check.passed) { "PASS" } else { "FAIL" }
    $Color = if ([bool]$Check.passed) { "Green" } else { "Red" }
    Write-Host "[$Label] $($Check.name): $($Check.details)" -ForegroundColor $Color
}

Write-Host ""
Write-Host "Ready: $($Readiness.ready) | Passed=$($Readiness.passed) | Failed=$($Readiness.failed)"
Write-Host ""

return $Readiness
