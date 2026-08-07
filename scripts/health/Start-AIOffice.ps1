param(
    [switch]$OpenDashboard
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Starting AI Office..." -ForegroundColor Cyan

$Token = & "E:\AI\AI-Office\scripts\health\Get-AIOfficeGatewayToken.ps1"
$env:OPENCLAW_GATEWAY_TOKEN = $Token

$State = & wsl.exe -d OpenClawGateway -- systemctl --user is-active openclaw-gateway 2>&1
$State = ([string]($State | Select-Object -First 1)).Trim()

if ($State -ne "active") {
    Write-Host "Starting OpenClaw Gateway..." -ForegroundColor Yellow
    & wsl.exe -d OpenClawGateway -- systemctl --user start openclaw-gateway
    Start-Sleep -Seconds 2
}

$Args = @("-NoProfile","-ExecutionPolicy","Bypass","-File","E:\AI\AI-Office\scripts\dashboard\Start-AIOfficeDashboard.ps1")
if ($OpenDashboard) { $Args += "-OpenBrowser" }

& powershell.exe @Args

& "E:\AI\AI-Office\scripts\health\Get-AIOfficeSystemHealth.ps1" -StartDashboardIfStopped | Out-Null

Write-Host "AI Office startup complete." -ForegroundColor Green
