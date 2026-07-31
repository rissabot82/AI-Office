param(
    [string]$Date = "",
    [string]$OwnerAgent = "",
    [switch]$IncludeCompleted,
    [switch]$SaveReport
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

if ([string]::IsNullOrWhiteSpace($Date)) {
    $agendaDate = (Get-Date).Date
}
else {
    $agendaDate = (ConvertTo-AIOfficeDateTime -Value $Date).Date
}

& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

$index = Get-Content `
    -LiteralPath ".\workspace\calendar\calendar-index.json" `
    -Raw |
    ConvertFrom-Json

$events = @(
    $index.events | Where-Object {
        $eventDate = (ConvertTo-AIOfficeDateTime -Value ([string]$_.start_at)).Date
        $eventDate -eq $agendaDate
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

$events = @(
    $events |
    Sort-Object `
        @{ Expression = { $_.start_at }; Descending = $false },
        @{ Expression = { $_.urgency_score }; Descending = $true }
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("AI OFFICE DAILY AGENDA")
$lines.Add($agendaDate.ToString("dddd, MMMM d, yyyy"))
$lines.Add(("=" * 60))
$lines.Add("")

if ($events.Count -eq 0) {
    $lines.Add("No scheduled events.")
}
else {
    foreach ($event in $events) {
        $start = ConvertTo-AIOfficeDateTime -Value ([string]$event.start_at)
        $end = ConvertTo-AIOfficeDateTime -Value ([string]$event.end_at)

        if ($event.all_day) {
            $timeText = "ALL DAY"
        }
        else {
            $timeText = "{0} - {1}" -f $start.ToString("hh:mm tt"), $end.ToString("hh:mm tt")
        }

        $lines.Add(
            "[{0}] {1} | {2} | {3} | urgency {4}" -f
            $timeText,
            $event.title,
            $event.priority,
            $event.status,
            $event.urgency_score
        )
    }
}

$totalMinutes = (
    $events |
    Measure-Object -Property estimated_minutes -Sum
).Sum

if ($null -eq $totalMinutes) {
    $totalMinutes = 0
}

$lines.Add("")
$lines.Add(("Scheduled events: {0}" -f $events.Count))
$lines.Add(("Estimated time: {0:N1} hours" -f ($totalMinutes / 60)))

$agendaText = $lines -join "`r`n"
Write-Host ""
Write-Host $agendaText

if ($SaveReport) {
    $reportPath = Join-Path `
        ".\workspace\calendar\agendas" `
        ("agenda-{0}.txt" -f $agendaDate.ToString("yyyy-MM-dd"))

    Set-Content -LiteralPath $reportPath -Value $agendaText -Encoding UTF8
    Write-Host ""
    Write-Host "Agenda saved: $reportPath" -ForegroundColor Green
}
