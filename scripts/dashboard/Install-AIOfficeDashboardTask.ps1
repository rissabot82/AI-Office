param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$TaskName = "AI Office Dashboard"
$StartScript = Join-Path $Root "scripts\dashboard\Start-AIOfficeDashboard.ps1"

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument (
        '-NoProfile -ExecutionPolicy Bypass -File "' +
        $StartScript +
        '"'
    ) `
    -WorkingDirectory $Root

$Trigger = New-ScheduledTaskTrigger -AtLogOn

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
    return
}

if ($null -ne $Existing) {
    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Starts the local AI Office dashboard at user logon." |
    Out-Null

Write-Host "Dashboard scheduled task installed." -ForegroundColor Green
