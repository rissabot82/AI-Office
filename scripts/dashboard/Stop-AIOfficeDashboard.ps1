param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$PidPath = Join-Path $Root "dashboard\runtime\dashboard.pid"

if (-not (Test-Path -LiteralPath $PidPath -PathType Leaf)) {
    Write-Host "Dashboard is not running." -ForegroundColor Yellow
    return
}

$ProcessId = (Get-Content -LiteralPath $PidPath -Raw).Trim()

if ($ProcessId -notmatch "^\d+$") {
    Remove-Item -LiteralPath $PidPath -Force
    throw "Dashboard PID file was invalid."
}

$Process = Get-Process -Id ([int]$ProcessId) -ErrorAction SilentlyContinue

if ($null -ne $Process) {
    Stop-Process -Id $Process.Id -Force
}

Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
Write-Host "AI Office Dashboard stopped." -ForegroundColor Green
