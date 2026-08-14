param()

$ErrorActionPreference = "Stop"

$TaskName = "AI Office Discord Worker"
$PowerShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$Script = "E:\AI\AI-Office\scripts\discord-office\Start-AIOfficeDiscordWorker.ps1"

$Action = New-ScheduledTaskAction `
    -Execute $PowerShell `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Script`""

$Trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Starts the AI Office Discord worker after the ClawAgent Windows account logs on." `
    -Force |
    Out-Null

Write-Host "Scheduled startup task installed: $TaskName" -ForegroundColor Green
