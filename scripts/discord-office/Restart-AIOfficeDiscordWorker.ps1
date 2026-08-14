param()

$ErrorActionPreference = "Stop"

& "E:\AI\AI-Office\scripts\discord-office\Stop-AIOfficeDiscordWorker.ps1"
Start-Sleep -Seconds 2
& "E:\AI\AI-Office\scripts\discord-office\Start-AIOfficeDiscordWorker.ps1"

Start-Sleep -Seconds 3

$State = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1"

Write-Host "Discord worker restart requested. Current state: $($State.status)" -ForegroundColor Green
return $State
