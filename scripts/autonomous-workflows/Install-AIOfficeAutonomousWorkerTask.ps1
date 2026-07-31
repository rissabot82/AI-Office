param(
    [int]$IntervalMinutes = 15,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$TaskName = "AI Office Autonomous Workflow Worker"
$PowerShell = (Get-Command powershell.exe).Source

if ($IntervalMinutes -lt 5) {
    throw "IntervalMinutes must be at least 5."
}

$ScriptPath = Join-Path `
    $Root `
    "scripts\autonomous-workflows\Invoke-AIOfficeAutonomousWorkerCycle.ps1"

$Arguments = (
    '-NoProfile -ExecutionPolicy Bypass -File "' +
    $ScriptPath +
    '"'
)

$Action = New-ScheduledTaskAction `
    -Execute $PowerShell `
    -Argument $Arguments `
    -WorkingDirectory $Root

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At ((Get-Date).AddMinutes(1)) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -RepetitionDuration ([timespan]::MaxValue)

$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

$Existing = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($null -ne $Existing -and -not $Force) {
    Write-Host "Scheduled task already exists: $TaskName" `
        -ForegroundColor Yellow

    return $Existing
}

if ($null -ne $Existing -and $Force) {
    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Runs AI Office autonomous workflow worker cycles." |
    Out-Null

Write-Host "Scheduled task installed: $TaskName" `
    -ForegroundColor Green

return Get-ScheduledTask -TaskName $TaskName
