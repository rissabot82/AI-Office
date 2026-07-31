$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$eventsRoot = ".\workspace\calendar\events"
$indexPath = ".\workspace\calendar\calendar-index.json"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$indexEvents = @()

$eventFiles = Get-ChildItem `
    -Path $eventsRoot `
    -Filter "event.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

foreach ($eventFile in $eventFiles) {
    try {
        $event = Get-Content -LiteralPath $eventFile.FullName -Raw | ConvertFrom-Json
        $startAt = ConvertTo-AIOfficeDateTime -Value ([string]$event.start_at)

        $event.urgency_score = Get-AIOfficeUrgencyScore `
            -Priority ([string]$event.priority) `
            -StartAt $startAt `
            -Status ([string]$event.status)

        Save-AIOfficeEvent -Event $event -Path $eventFile.FullName

        $relativeFolder = $eventFile.Directory.FullName.Substring(
            $repositoryRoot.Length
        ).TrimStart("\", "/")

        $indexEvents += [PSCustomObject]@{
            event_id = [string]$event.event_id
            title = [string]$event.title
            description = [string]$event.description
            event_type = [string]$event.event_type
            status = [string]$event.status
            priority = [string]$event.priority
            start_at = [string]$event.start_at
            end_at = [string]$event.end_at
            all_day = [bool]$event.all_day
            owner_agent = [string]$event.owner_agent
            estimated_minutes = [int]$event.estimated_minutes
            actual_minutes = [int]$event.actual_minutes
            recurrence = [string]$event.recurrence.frequency
            urgency_score = [int]$event.urgency_score
            project_id = $event.links.project_id
            workflow_id = $event.links.workflow_id
            task_id = $event.links.task_id
            tags = @($event.tags)
            folder = $relativeFolder
            search_text = (
                @(
                    $event.title,
                    $event.description,
                    $event.event_type,
                    $event.priority,
                    $event.status,
                    $event.owner_agent,
                    (@($event.tags) -join " ")
                ) -join "`n"
            ).ToLowerInvariant()
        }
    }
    catch {
        Write-Warning "Skipped invalid calendar event: $($eventFile.FullName)"
    }
}

$index = [ordered]@{
    version = "1.0.0"
    generated_at = $timestamp
    total_events = $indexEvents.Count
    events = @(
        $indexEvents |
        Sort-Object start_at
    )
}

$index |
    ConvertTo-Json -Depth 30 |
    Set-Content -LiteralPath $indexPath -Encoding UTF8

Write-Host "Calendar index updated: $($indexEvents.Count) event(s)." -ForegroundColor Green
