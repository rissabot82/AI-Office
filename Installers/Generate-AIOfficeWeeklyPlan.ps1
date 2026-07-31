param(
    [string]$WeekOf = "",
    [string]$OwnerAgent = "",
    [switch]$IncludeCompleted,
    [switch]$SaveReport
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

if ([string]::IsNullOrWhiteSpace($WeekOf)) {
    $referenceDate = (Get-Date).Date
}
else {
    $referenceDate = (ConvertTo-AIOfficeDateTime -Value $WeekOf).Date
}

$dayOffset = ([int]$referenceDate.DayOfWeek + 6) % 7
$weekStart = $referenceDate.AddDays(-$dayOffset)
$weekEnd = $weekStart.AddDays(6)

& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

$index = Get-Content `
    -LiteralPath ".\workspace\calendar\calendar-index.json" `
    -Raw |
    ConvertFrom-Json

$events = @(
    $index.events | Where-Object {
        $eventDate = (ConvertTo-AIOfficeDateTime -Value ([string]$_.start_at)).Date
        $eventDate -ge $weekStart -and $eventDate -le $weekEnd
    }
)

if (-not $IncludeCompleted) {
    $events = @(
        $events | Where-Object {
            $_.status -notin @("completed", "cancelled", "archived")
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($OwnerAgent)) {
    $events = @(
        $events | Where-Object {
            $_.owner_agent -eq $OwnerAgent
        }
    )
}

$policy = Get-Content `
    -LiteralPath ".\config\calendar\calendar-policy.json" `
    -Raw |
    ConvertFrom-Json

$workStart = [timespan]::Parse([string]$policy.working_hours.start)
$workEnd = [timespan]::Parse([string]$policy.working_hours.end)
$dailyCapacityMinutes = [int](($workEnd - $workStart).TotalMinutes)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("AI OFFICE WEEKLY PLAN")
$lines.Add(
    (
        "{0} through {1}" -f
        $weekStart.ToString("MMMM d, yyyy"),
        $weekEnd.ToString("MMMM d, yyyy")
    )
)
$lines.Add(("=" * 70))
$lines.Add("")

for ($i = 0; $i -lt 7; $i++) {
    $day = $weekStart.AddDays($i)
    $dayEvents = @(
        $events |
        Where-Object {
            (ConvertTo-AIOfficeDateTime -Value ([string]$_.start_at)).Date -eq $day
        } |
        Sort-Object start_at
    )

    $scheduledMinutes = (
        $dayEvents |
        Measure-Object -Property estimated_minutes -Sum
    ).Sum

    if ($null -eq $scheduledMinutes) {
        $scheduledMinutes = 0
    }

    $isWorkingDay = @($policy.working_days) -contains $day.DayOfWeek.ToString()
    $capacity = if ($isWorkingDay) { $dailyCapacityMinutes } else { 0 }
    $remaining = [math]::Max(0, $capacity - $scheduledMinutes)

    $lines.Add($day.ToString("dddd, MMMM d"))
    $lines.Add(
        (
            "Capacity: {0:N1}h | Scheduled: {1:N1}h | Remaining: {2:N1}h" -f
            ($capacity / 60),
            ($scheduledMinutes / 60),
            ($remaining / 60)
        )
    )

    if ($dayEvents.Count -eq 0) {
        $lines.Add("  No scheduled events.")
    }
    else {
        foreach ($event in $dayEvents) {
            $start = ConvertTo-AIOfficeDateTime -Value ([string]$event.start_at)
            $lines.Add(
                "  {0} | {1} | {2} | {3}" -f
                $start.ToString("hh:mm tt"),
                $event.priority,
                $event.status,
                $event.title
            )
        }
    }

    $lines.Add("")
}

$reportText = $lines -join "`r`n"
Write-Host ""
Write-Host $reportText

if ($SaveReport) {
    $reportPath = Join-Path `
        ".\workspace\calendar\reports" `
        ("weekly-plan-{0}.txt" -f $weekStart.ToString("yyyy-MM-dd"))

    Set-Content -LiteralPath $reportPath -Value $reportText -Encoding UTF8
    Write-Host "Weekly plan saved: $reportPath" -ForegroundColor Green
}