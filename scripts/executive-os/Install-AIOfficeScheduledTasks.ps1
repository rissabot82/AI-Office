param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$dailyScript = Join-Path $root.Path "scripts\executive-os\Invoke-AIOfficeDailyRoutine.ps1"
$eodScript = Join-Path $root.Path "scripts\executive-os\New-AIOfficeEndOfDayReport.ps1"
$weeklyScript = Join-Path $root.Path "scripts\executive-os\New-AIOfficeWeeklyReport.ps1"
$monthlyScript = Join-Path $root.Path "scripts\executive-os\New-AIOfficeMonthlyReport.ps1"

$tasks = @(
    @{
        Name = "AI Office Daily Startup"
        Time = "07:00"
        Schedule = "DAILY"
        Script = $dailyScript
    },
    @{
        Name = "AI Office End of Day"
        Time = "18:00"
        Schedule = "DAILY"
        Script = $eodScript
    }
)

foreach ($task in $tasks) {
    $arguments = @(
        "/Create",
        "/TN", $task.Name,
        "/SC", $task.Schedule,
        "/ST", $task.Time,
        "/TR",
        ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $task.Script + '"')
    )

    if ($Force) {
        $arguments += "/F"
    }

    & schtasks.exe @arguments | Out-Null
    Write-Host ("Scheduled task created: " + $task.Name) -ForegroundColor Green
}

Write-Host ""
Write-Host "Weekly and monthly reports can be scheduled manually if desired." `
    -ForegroundColor Yellow
Write-Host ("Weekly script: " + $weeklyScript)
Write-Host ("Monthly script: " + $monthlyScript)
