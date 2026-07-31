$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

Write-Host ""
Write-Host "Testing AI Office calendar and scheduling engine..." -ForegroundColor Cyan
Write-Host ""

$errorsFound = 0

$jsonFiles = @(
    ".\config\calendar\calendar-policy.json",
    ".\config\calendar\calendar-event-schema.json",
    ".\workspace\calendar\calendar-index.json",
    ".\workspace\templates\calendar-event-template.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID   ] $file" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

$requiredScripts = @(
    ".\scripts\calendar\AIOfficeCalendar.Common.ps1",
    ".\scripts\calendar\New-AIOfficeEvent.ps1",
    ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1",
    ".\scripts\calendar\Show-AIOfficeEvent.ps1",
    ".\scripts\calendar\Search-AIOfficeEvents.ps1",
    ".\scripts\calendar\Update-AIOfficeEvent.ps1",
    ".\scripts\calendar\Complete-AIOfficeEvent.ps1",
    ".\scripts\calendar\Archive-AIOfficeEvent.ps1",
    ".\scripts\calendar\Generate-AIOfficeAgenda.ps1",
    ".\scripts\calendar\Generate-AIOfficeWeeklyPlan.ps1",
    ".\scripts\calendar\Expand-AIOfficeRecurringEvents.ps1",
    ".\scripts\calendar\Sync-AIOfficeWorkflowCalendar.ps1"
)

foreach ($script in $requiredScripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING     ] $script" -ForegroundColor Red
        $errorsFound++
    }
}

try {
    . ".\scripts\calendar\AIOfficeCalendar.Common.ps1"

    $testDate = ConvertTo-AIOfficeDateTime -Value "2026-07-31 08:00"
    $score = Get-AIOfficeUrgencyScore `
        -Priority "high" `
        -StartAt $testDate `
        -Status "scheduled"

    if ($score -is [int]) {
        Write-Host "[URGENCY OK ] Priority calculation returned $score" -ForegroundColor Green
    }
    else {
        throw "Urgency calculation did not return an integer."
    }
}
catch {
    Write-Host "[URGENCY ERR] Priority calculation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errorsFound++
}

$eventFiles = Get-ChildItem `
    -Path ".\workspace\calendar\events" `
    -Filter "event.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

foreach ($eventFile in $eventFiles) {
    try {
        $event = Get-Content -LiteralPath $eventFile.FullName -Raw | ConvertFrom-Json

        foreach ($requiredField in @(
            "event_id",
            "title",
            "event_type",
            "status",
            "priority",
            "start_at",
            "end_at",
            "recurrence",
            "links",
            "tags",
            "history"
        )) {
            if (-not ($event.PSObject.Properties.Name -contains $requiredField)) {
                throw "Required field is missing: $requiredField"
            }
        }

        $startAt = ConvertTo-AIOfficeDateTime -Value ([string]$event.start_at)
        $endAt = ConvertTo-AIOfficeDateTime -Value ([string]$event.end_at)

        if ($endAt -lt $startAt) {
            throw "Event end time is earlier than start time."
        }

        Write-Host "[VALID EVENT] $($event.event_id)" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID    ] $($eventFile.FullName)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

try {
    & ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

    $index = Get-Content `
        -LiteralPath ".\workspace\calendar\calendar-index.json" `
        -Raw |
        ConvertFrom-Json

    Write-Host "[INDEX OK   ] $($index.total_events) calendar event(s)" -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERROR] Calendar index failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errorsFound++
}

try {
    $todayText = Get-Date -Format "yyyy-MM-dd"

    & ".\scripts\calendar\Generate-AIOfficeAgenda.ps1" `
        -Date $todayText |
        Out-Null

    Write-Host "[AGENDA OK  ] Daily agenda generation passed." -ForegroundColor Green
}
catch {
    Write-Host "[AGENDA ERR ] Daily agenda generation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errorsFound++
}

try {
    $todayText = Get-Date -Format "yyyy-MM-dd"

    & ".\scripts\calendar\Generate-AIOfficeWeeklyPlan.ps1" `
        -WeekOf $todayText |
        Out-Null

    Write-Host "[WEEKLY OK  ] Weekly planning generation passed." -ForegroundColor Green
}
catch {
    Write-Host "[WEEKLY ERR ] Weekly planning generation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errorsFound++
}

Write-Host ""

if ($errorsFound -eq 0) {
    Write-Host "All calendar management checks passed." -ForegroundColor Green
}
else {
    Write-Host (
        "{0} calendar management error or errors were found." -f
        $errorsFound
    ) -ForegroundColor Red

    exit 1
}
