param()

$ErrorActionPreference = "Stop"

$Processes = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        $_.CommandLine -and
        $_.CommandLine.Contains("Invoke-AIOfficeDiscordWorker.ps1")
    }

foreach ($Process in @($Processes)) {
    Stop-Process -Id ([int]$Process.ProcessId) -Force -ErrorAction SilentlyContinue
}

$StatePath = "E:\AI\AI-Office\workspace\discord-office\state\worker-state.json"
if (Test-Path -LiteralPath $StatePath) {
    $State = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    $State.status = "stopped"
    $State.updated_at = (Get-Date).ToString("o")
    $State | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $StatePath -Encoding UTF8
}

Write-Host "AI Office Discord worker stopped." -ForegroundColor Green
