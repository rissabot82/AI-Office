param(
    [switch]$Foreground
)

$ErrorActionPreference = "Stop"

$WorkerScript = "E:\AI\AI-Office\scripts\discord-office\Invoke-AIOfficeDiscordWorker.ps1"

if (-not (Test-Path -LiteralPath $WorkerScript)) {
    throw "Discord worker script not found."
}

if ($Foreground) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $WorkerScript
    exit $LASTEXITCODE
}

$Existing = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        $_.CommandLine -and
        $_.CommandLine.Contains("Invoke-AIOfficeDiscordWorker.ps1")
    }

if (@($Existing).Count -gt 0) {
    Write-Host "AI Office Discord worker is already running." -ForegroundColor Yellow
    return
}

$Process = Start-Process `
    -FilePath "powershell.exe" `
    -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$WorkerScript`""
    ) `
    -WindowStyle Hidden `
    -PassThru

Write-Host "AI Office Discord worker started. PID=$($Process.Id)" -ForegroundColor Green
