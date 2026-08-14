param()

$ErrorActionPreference = "Stop"

& "E:\AI\AI-Office\scripts\discord-office\Stop-AIOfficeDiscordWorker.ps1"

$State = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1"

Write-Host "AI Office Discord live operations disabled. Worker=$($State.status)" -ForegroundColor Green
return $State
