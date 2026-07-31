# ============================================================
# AI Office Package 11
# Calendar and Scheduling Engine
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"

$expectedRepository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $expectedRepository -PathType Container)) {
    throw "AI Office repository not found at $expectedRepository"
}

Set-Location $expectedRepository

function New-SafeDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function New-SafeFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $parent = Split-Path -Parent $Path

        if (
            -not [string]::IsNullOrWhiteSpace($parent) -and
            -not (Test-Path -LiteralPath $parent -PathType Container)
        ) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

$requiredFolders = @(
    ".\config\calendar",
    ".\workspace\calendar",
    ".\workspace\calendar\events",
    ".\workspace\calendar\archive",
    ".\workspace\calendar\agendas",
    ".\workspace\calendar\reports",
    ".\scripts\calendar",
    ".\docs",
    ".\Installers"
)

foreach ($folder in $requiredFolders) {
    New-SafeDirectory -Path $folder
}

$calendarPolicy = @'
{
  "version": "1.0.0",
  "default_timezone": "America/Chicago",
  "default_owner": "chief-of-staff",
  "default_status": "scheduled",
  "default_priority": "normal",
  "default_visibility": "internal",
  "default_duration_minutes": 60,
  "working_days": [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday"
  ],
  "working_hours": {
    "start": "08:00",
    "end": "17:00"
  },
  "priority_weights": {
    "critical": 100,
    "high": 70,
    "normal": 40,
    "low": 10
  },
  "overdue_weight": 100,
  "due_today_weight": 60,
  "due_this_week_weight": 30,
  "allow_recurring_events": true,
  "archive_completed_events": false,
  "supported_event_types": [
    "meeting",
    "deadline",
    "milestone",
    "reminder",
    "task",
    "time-block",
    "review"
  ],
  "supported_statuses": [
    "scheduled",
    "in-progress",
    "completed",
    "cancelled",
    "deferred",
    "archived"
  ],
  "supported_priorities": [
    "critical",
    "high",
    "normal",
    "low"
  ],
  "supported_recurrence": [
    "none",
    "daily",
    "weekly",
    "monthly",
    "yearly"
  ]
}
'@

New-SafeFile ".\config\calendar\calendar-policy.json" $calendarPolicy

$eventSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/calendar-event-schema.json",
  "title": "AI Office Calendar Event",
  "type": "object",
  "required": [
    "event_id",
    "title",
    "description",
    "event_type",
    "status",
    "priority",
    "start_at",
    "end_at",
    "all_day",
    "timezone",
    "owner_agent",
    "created_by",
    "created_at",
    "updated_at",
    "estimated_minutes",
    "actual_minutes",
    "recurrence",
    "links",
    "tags",
    "history"
  ],
  "properties": {
    "event_id": {
      "type": "string",
      "pattern": "^EVT-[0-9]{8}-[0-9]{4}$"
    },
    "title": {
      "type": "string",
      "minLength": 1
    },
    "description": {
      "type": "string"
    },
    "event_type": {
      "type": "string",
      "enum": [
        "meeting",
        "deadline",
        "milestone",
        "reminder",
        "task",
        "time-block",
        "review"
      ]
    },
    "status": {
      "type": "string",
      "enum": [
        "scheduled",
        "in-progress",
        "completed",
        "cancelled",
        "deferred",
        "archived"
      ]
    },
    "priority": {
      "type": "string",
      "enum": [
        "critical",
        "high",
        "normal",
        "low"
      ]
    },
    "start_at": {
      "type": "string"
    },
    "end_at": {
      "type": "string"
    },
    "all_day": {
      "type": "boolean"
    },
    "timezone": {
      "type": "string"
    },
    "owner_agent": {
      "type": "string"
    },
    "created_by": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    },
    "completed_at": {
      "type": [
        "string",
        "null"
      ]
    },
    "estimated_minutes": {
      "type": "integer",
      "minimum": 0
    },
    "actual_minutes": {
      "type": "integer",
      "minimum": 0
    },
    "location": {
      "type": "string"
    },
    "recurrence": {
      "type": "object",
      "required": [
        "frequency",
        "interval",
        "until",
        "count"
      ],
      "properties": {
        "frequency": {
          "type": "string",
          "enum": [
            "none",
            "daily",
            "weekly",
            "monthly",
            "yearly"
          ]
        },
        "interval": {
          "type": "integer",
          "minimum": 1
        },
        "until": {
          "type": [
            "string",
            "null"
          ]
        },
        "count": {
          "type": [
            "integer",
            "null"
          ],
          "minimum": 1
        }
      }
    },
    "links": {
      "type": "object",
      "required": [
        "project_id",
        "workflow_id",
        "task_id",
        "knowledge_ids"
      ],
      "properties": {
        "project_id": {
          "type": [
            "string",
            "null"
          ]
        },
        "workflow_id": {
          "type": [
            "string",
            "null"
          ]
        },
        "task_id": {
          "type": [
            "string",
            "null"
          ]
        },
        "knowledge_ids": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      }
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "urgency_score": {
      "type": "integer"
    },
    "history": {
      "type": "array",
      "items": {
        "type": "object"
      }
    }
  }
}
'@

New-SafeFile ".\config\calendar\calendar-event-schema.json" $eventSchema

$calendarIndex = @'
{
  "version": "1.0.0",
  "generated_at": null,
  "total_events": 0,
  "events": []
}
'@

New-SafeFile ".\workspace\calendar\calendar-index.json" $calendarIndex

$eventTemplate = @'
{
  "event_id": "EVT-YYYYMMDD-0001",
  "title": "Calendar event title",
  "description": "",
  "event_type": "task",
  "status": "scheduled",
  "priority": "normal",
  "start_at": "YYYY-MM-DDTHH:MM:SS",
  "end_at": "YYYY-MM-DDTHH:MM:SS",
  "all_day": false,
  "timezone": "America/Chicago",
  "owner_agent": "chief-of-staff",
  "created_by": "Clarissa",
  "created_at": "YYYY-MM-DDTHH:MM:SS",
  "updated_at": "YYYY-MM-DDTHH:MM:SS",
  "completed_at": null,
  "estimated_minutes": 60,
  "actual_minutes": 0,
  "location": "",
  "recurrence": {
    "frequency": "none",
    "interval": 1,
    "until": null,
    "count": null
  },
  "links": {
    "project_id": null,
    "workflow_id": null,
    "task_id": null,
    "knowledge_ids": []
  },
  "tags": [],
  "urgency_score": 0,
  "history": []
}
'@

New-SafeFile ".\workspace\templates\calendar-event-template.json" $eventTemplate

$calendarModule = @'
function Get-AIOfficeCalendarRoot {
    $repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    return $repositoryRoot.Path
}

function ConvertTo-AIOfficeDateTime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $parsed = [datetime]::MinValue

    if (-not [datetime]::TryParse($Value, [ref]$parsed)) {
        throw "Invalid date or date-time value: $Value"
    }

    return $parsed
}

function Get-AIOfficeUrgencyScore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Priority,

        [Parameter(Mandatory = $true)]
        [datetime]$StartAt,

        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    if ($Status -in @("completed", "cancelled", "archived")) {
        return 0
    }

    $priorityScores = @{
        critical = 100
        high = 70
        normal = 40
        low = 10
    }

    $score = [int]$priorityScores[$Priority]
    $now = Get-Date
    $today = $now.Date
    $daysUntil = [math]::Floor(($StartAt.Date - $today).TotalDays)

    if ($StartAt -lt $now) {
        $score += 100
    }
    elseif ($StartAt.Date -eq $today) {
        $score += 60
    }
    elseif ($daysUntil -le 7) {
        $score += 30
    }
    elseif ($daysUntil -le 30) {
        $score += 10
    }

    return $score
}

function Get-AIOfficeEventFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EventId
    )

    $root = Get-AIOfficeCalendarRoot
    return Join-Path $root "workspace\calendar\events\$EventId\event.json"
}

function Save-AIOfficeEvent {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Event,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Event |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeEvent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EventId
    )

    $path = Get-AIOfficeEventFile -EventId $EventId

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Calendar event not found: $EventId"
    }

    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}
'@

New-SafeFile ".\scripts\calendar\AIOfficeCalendar.Common.ps1" $calendarModule

$newEventScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [string]$Description = "",

    [ValidateSet(
        "meeting",
        "deadline",
        "milestone",
        "reminder",
        "task",
        "time-block",
        "review"
    )]
    [string]$EventType = "task",

    [ValidateSet(
        "critical",
        "high",
        "normal",
        "low"
    )]
    [string]$Priority = "normal",

    [Parameter(Mandatory = $true)]
    [string]$StartAt,

    [string]$EndAt = "",
    [switch]$AllDay,
    [int]$EstimatedMinutes = 60,
    [string]$Timezone = "America/Chicago",
    [string]$OwnerAgent = "chief-of-staff",
    [string]$CreatedBy = "Clarissa",
    [string]$Location = "",

    [ValidateSet(
        "none",
        "daily",
        "weekly",
        "monthly",
        "yearly"
    )]
    [string]$Recurrence = "none",

    [ValidateRange(1, 999)]
    [int]$RecurrenceInterval = 1,

    [string]$RecurrenceUntil = "",
    [Nullable[int]]$RecurrenceCount = $null,
    [string]$ProjectId = "",
    [string]$WorkflowId = "",
    [string]$TaskId = "",
    [string[]]$KnowledgeIds = @(),
    [string[]]$Tags = @()
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$startDateTime = ConvertTo-AIOfficeDateTime -Value $StartAt

if ([string]::IsNullOrWhiteSpace($EndAt)) {
    $endDateTime = $startDateTime.AddMinutes($EstimatedMinutes)
}
else {
    $endDateTime = ConvertTo-AIOfficeDateTime -Value $EndAt
}

if ($endDateTime -lt $startDateTime) {
    throw "EndAt cannot be earlier than StartAt."
}

if ($AllDay) {
    $startDateTime = $startDateTime.Date
    $endDateTime = $startDateTime.Date.AddDays(1)
}

$untilValue = $null

if (-not [string]::IsNullOrWhiteSpace($RecurrenceUntil)) {
    $untilValue = (ConvertTo-AIOfficeDateTime -Value $RecurrenceUntil).ToString("yyyy-MM-ddTHH:mm:ss")
}

$today = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$itemsRoot = Join-Path $repositoryRoot "workspace\calendar\events"

$existingFolders = Get-ChildItem `
    -LiteralPath $itemsRoot `
    -Directory `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match "^EVT-$today-(\d{4})$"
    }

$highestNumber = 0

foreach ($folder in $existingFolders) {
    if ($folder.Name -match "^EVT-$today-(\d{4})$") {
        $number = [int]$Matches[1]

        if ($number -gt $highestNumber) {
            $highestNumber = $number
        }
    }
}

$eventId = "EVT-$today-{0:D4}" -f ($highestNumber + 1)
$eventFolder = Join-Path $itemsRoot $eventId
New-Item -ItemType Directory -Path $eventFolder -Force | Out-Null

$normalizedTags = @(
    $Tags |
    ForEach-Object { ([string]$_).Trim().ToLowerInvariant() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique
)

$normalizedKnowledgeIds = @(
    $KnowledgeIds |
    ForEach-Object { ([string]$_).Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique
)

$urgencyScore = Get-AIOfficeUrgencyScore `
    -Priority $Priority `
    -StartAt $startDateTime `
    -Status "scheduled"

$event = [ordered]@{
    event_id = $eventId
    title = $Title
    description = $Description
    event_type = $EventType
    status = "scheduled"
    priority = $Priority
    start_at = $startDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
    end_at = $endDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
    all_day = [bool]$AllDay
    timezone = $Timezone
    owner_agent = $OwnerAgent
    created_by = $CreatedBy
    created_at = $timestamp
    updated_at = $timestamp
    completed_at = $null
    estimated_minutes = [int]$EstimatedMinutes
    actual_minutes = 0
    location = $Location
    recurrence = [ordered]@{
        frequency = $Recurrence
        interval = $RecurrenceInterval
        until = $untilValue
        count = $RecurrenceCount
    }
    links = [ordered]@{
        project_id = if ([string]::IsNullOrWhiteSpace($ProjectId)) { $null } else { $ProjectId }
        workflow_id = if ([string]::IsNullOrWhiteSpace($WorkflowId)) { $null } else { $WorkflowId }
        task_id = if ([string]::IsNullOrWhiteSpace($TaskId)) { $null } else { $TaskId }
        knowledge_ids = $normalizedKnowledgeIds
    }
    tags = $normalizedTags
    urgency_score = $urgencyScore
    history = @(
        [ordered]@{
            timestamp = $timestamp
            action = "event-created"
            actor = $CreatedBy
            details = "Calendar event created."
        }
    )
}

$eventPath = Join-Path $eventFolder "event.json"
Save-AIOfficeEvent -Event $event -Path $eventPath

& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Calendar event created successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Event ID:   $eventId"
Write-Host "Title:      $Title"
Write-Host "Type:       $EventType"
Write-Host "Priority:   $Priority"
Write-Host "Start:      $($event.start_at)"
Write-Host "End:        $($event.end_at)"
Write-Host "Recurrence: $Recurrence"
'@

New-SafeFile ".\scripts\calendar\New-AIOfficeEvent.ps1" $newEventScript

$updateIndexScript = @'
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
'@

New-SafeFile ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" $updateIndexScript

$showEventScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$EventId,

    [switch]$ShowHistory
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$event = Get-AIOfficeEvent -EventId $EventId

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AI Office Calendar Event" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Event ID:        $($event.event_id)"
Write-Host "Title:           $($event.title)"
Write-Host "Description:     $($event.description)"
Write-Host "Type:            $($event.event_type)"
Write-Host "Status:          $($event.status)"
Write-Host "Priority:        $($event.priority)"
Write-Host "Urgency score:   $($event.urgency_score)"
Write-Host "Start:           $($event.start_at)"
Write-Host "End:             $($event.end_at)"
Write-Host "All day:         $($event.all_day)"
Write-Host "Timezone:        $($event.timezone)"
Write-Host "Owner:           $($event.owner_agent)"
Write-Host "Estimated:       $($event.estimated_minutes) minutes"
Write-Host "Actual:          $($event.actual_minutes) minutes"
Write-Host "Location:        $($event.location)"
Write-Host "Recurrence:      $($event.recurrence.frequency)"
Write-Host "Project:         $($event.links.project_id)"
Write-Host "Workflow:        $($event.links.workflow_id)"
Write-Host "Task:            $($event.links.task_id)"
Write-Host "Knowledge items: $(@($event.links.knowledge_ids) -join ', ')"
Write-Host "Tags:            $(@($event.tags) -join ', ')"
Write-Host "Created:         $($event.created_at)"
Write-Host "Updated:         $($event.updated_at)"
Write-Host "Completed:       $($event.completed_at)"

if ($ShowHistory) {
    Write-Host ""
    Write-Host "History" -ForegroundColor Cyan
    Write-Host "-------" -ForegroundColor Cyan

    foreach ($entry in @($event.history)) {
        Write-Host (
            "{0} | {1} | {2} | {3}" -f
            $entry.timestamp,
            $entry.action,
            $entry.actor,
            $entry.details
        )
    }
}
'@

New-SafeFile ".\scripts\calendar\Show-AIOfficeEvent.ps1" $showEventScript

$searchEventsScript = @'
param(
    [string]$Query = "",
    [string]$EventType = "",
    [string]$Status = "",
    [string]$Priority = "",
    [string]$OwnerAgent = "",
    [string]$Tag = "",
    [string]$From = "",
    [string]$To = "",
    [int]$Limit = 50,
    [switch]$IncludeCompleted,
    [switch]$IncludeCancelled
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

$index = Get-Content `
    -LiteralPath ".\workspace\calendar\calendar-index.json" `
    -Raw |
    ConvertFrom-Json

$results = @($index.events)

if (-not $IncludeCompleted) {
    $results = @($results | Where-Object { $_.status -ne "completed" })
}

if (-not $IncludeCancelled) {
    $results = @($results | Where-Object { $_.status -ne "cancelled" })
}

if (-not [string]::IsNullOrWhiteSpace($Query)) {
    $queryText = $Query.ToLowerInvariant()
    $results = @(
        $results | Where-Object {
            ([string]$_.search_text).Contains($queryText)
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($EventType)) {
    $results = @($results | Where-Object { $_.event_type -eq $EventType })
}

if (-not [string]::IsNullOrWhiteSpace($Status)) {
    $results = @($results | Where-Object { $_.status -eq $Status })
}

if (-not [string]::IsNullOrWhiteSpace($Priority)) {
    $results = @($results | Where-Object { $_.priority -eq $Priority })
}

if (-not [string]::IsNullOrWhiteSpace($OwnerAgent)) {
    $results = @($results | Where-Object { $_.owner_agent -eq $OwnerAgent })
}

if (-not [string]::IsNullOrWhiteSpace($Tag)) {
    $tagText = $Tag.Trim().ToLowerInvariant()
    $results = @($results | Where-Object { @($_.tags) -contains $tagText })
}

if (-not [string]::IsNullOrWhiteSpace($From)) {
    $fromDate = ConvertTo-AIOfficeDateTime -Value $From
    $results = @(
        $results | Where-Object {
            (ConvertTo-AIOfficeDateTime -Value ([string]$_.start_at)) -ge $fromDate
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($To)) {
    $toDate = ConvertTo-AIOfficeDateTime -Value $To
    $results = @(
        $results | Where-Object {
            (ConvertTo-AIOfficeDateTime -Value ([string]$_.start_at)) -le $toDate
        }
    )
}

$results = @(
    $results |
    Sort-Object `
        @{ Expression = { $_.urgency_score }; Descending = $true },
        @{ Expression = { $_.start_at }; Descending = $false } |
    Select-Object -First $Limit
)

Write-Host ""
Write-Host "Calendar search results: $($results.Count)" -ForegroundColor Cyan
Write-Host ""

if ($results.Count -eq 0) {
    Write-Host "No matching calendar events were found." -ForegroundColor Yellow
    exit 0
}

$rows = foreach ($event in $results) {
    [PSCustomObject]@{
        EventId = $event.event_id
        Start = $event.start_at
        Type = $event.event_type
        Priority = $event.priority
        Status = $event.status
        Urgency = $event.urgency_score
        Title = $event.title
    }
}

$rows | Format-Table -AutoSize
'@

New-SafeFile ".\scripts\calendar\Search-AIOfficeEvents.ps1" $searchEventsScript

$updateEventScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$EventId,

    [string]$Title = "",
    [string]$Description = "",

    [ValidateSet(
        "",
        "meeting",
        "deadline",
        "milestone",
        "reminder",
        "task",
        "time-block",
        "review"
    )]
    [string]$EventType = "",

    [ValidateSet(
        "",
        "scheduled",
        "in-progress",
        "completed",
        "cancelled",
        "deferred",
        "archived"
    )]
    [string]$Status = "",

    [ValidateSet(
        "",
        "critical",
        "high",
        "normal",
        "low"
    )]
    [string]$Priority = "",

    [string]$StartAt = "",
    [string]$EndAt = "",
    [Nullable[int]]$EstimatedMinutes = $null,
    [Nullable[int]]$ActualMinutes = $null,
    [string]$OwnerAgent = "",
    [string]$Location = "",
    [string[]]$Tags,
    [string]$UpdatedBy = "Clarissa",
    [string]$ChangeNote = "Calendar event updated."
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$eventPath = Get-AIOfficeEventFile -EventId $EventId
$event = Get-AIOfficeEvent -EventId $EventId
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

if (-not [string]::IsNullOrWhiteSpace($Title)) {
    $event.title = $Title
}

if ($PSBoundParameters.ContainsKey("Description")) {
    $event.description = $Description
}

if (-not [string]::IsNullOrWhiteSpace($EventType)) {
    $event.event_type = $EventType
}

if (-not [string]::IsNullOrWhiteSpace($Status)) {
    $event.status = $Status
}

if (-not [string]::IsNullOrWhiteSpace($Priority)) {
    $event.priority = $Priority
}

if (-not [string]::IsNullOrWhiteSpace($StartAt)) {
    $event.start_at = (ConvertTo-AIOfficeDateTime -Value $StartAt).ToString("yyyy-MM-ddTHH:mm:ss")
}

if (-not [string]::IsNullOrWhiteSpace($EndAt)) {
    $event.end_at = (ConvertTo-AIOfficeDateTime -Value $EndAt).ToString("yyyy-MM-ddTHH:mm:ss")
}

$startDateTime = ConvertTo-AIOfficeDateTime -Value ([string]$event.start_at)
$endDateTime = ConvertTo-AIOfficeDateTime -Value ([string]$event.end_at)

if ($endDateTime -lt $startDateTime) {
    throw "EndAt cannot be earlier than StartAt."
}

if ($null -ne $EstimatedMinutes) {
    $event.estimated_minutes = [int]$EstimatedMinutes
}

if ($null -ne $ActualMinutes) {
    $event.actual_minutes = [int]$ActualMinutes
}

if (-not [string]::IsNullOrWhiteSpace($OwnerAgent)) {
    $event.owner_agent = $OwnerAgent
}

if ($PSBoundParameters.ContainsKey("Location")) {
    $event.location = $Location
}

if ($PSBoundParameters.ContainsKey("Tags")) {
    $event.tags = @(
        $Tags |
        ForEach-Object { ([string]$_).Trim().ToLowerInvariant() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
    )
}

$event.updated_at = $timestamp
$event.urgency_score = Get-AIOfficeUrgencyScore `
    -Priority ([string]$event.priority) `
    -StartAt $startDateTime `
    -Status ([string]$event.status)

$event.history = @($event.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "event-updated"
    actor = $UpdatedBy
    details = $ChangeNote
}

Save-AIOfficeEvent -Event $event -Path $eventPath
& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Calendar event updated successfully." -ForegroundColor Green
Write-Host "Event ID: $EventId"
Write-Host "Status:   $($event.status)"
Write-Host "Start:    $($event.start_at)"
Write-Host "End:      $($event.end_at)"
'@

New-SafeFile ".\scripts\calendar\Update-AIOfficeEvent.ps1" $updateEventScript

$completeEventScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$EventId,

    [int]$ActualMinutes = 0,
    [string]$CompletedBy = "Clarissa",
    [string]$CompletionNote = "Calendar event completed."
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$eventPath = Get-AIOfficeEventFile -EventId $EventId
$event = Get-AIOfficeEvent -EventId $EventId
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

if ($event.status -eq "completed") {
    Write-Host "Calendar event is already completed: $EventId" -ForegroundColor Yellow
    exit 0
}

$event.status = "completed"
$event.completed_at = $timestamp
$event.updated_at = $timestamp
$event.actual_minutes = $ActualMinutes
$event.urgency_score = 0
$event.history = @($event.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "event-completed"
    actor = $CompletedBy
    details = $CompletionNote
}

Save-AIOfficeEvent -Event $event -Path $eventPath
& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Calendar event completed successfully." -ForegroundColor Green
Write-Host "Event ID:       $EventId"
Write-Host "Completed at:   $timestamp"
Write-Host "Actual minutes: $ActualMinutes"
'@

New-SafeFile ".\scripts\calendar\Complete-AIOfficeEvent.ps1" $completeEventScript

$archiveEventScript = @'
param(
    [Parameter(Mandatory = $true)]
    [string]$EventId,

    [string]$ArchivedBy = "Clarissa",
    [string]$Reason = "Calendar event archived."
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$eventFolder = Join-Path ".\workspace\calendar\events" $EventId
$eventPath = Join-Path $eventFolder "event.json"

if (-not (Test-Path -LiteralPath $eventPath -PathType Leaf)) {
    throw "Calendar event not found: $EventId"
}

$event = Get-Content -LiteralPath $eventPath -Raw | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$event.status = "archived"
$event.updated_at = $timestamp
$event.urgency_score = 0
$event.history = @($event.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "event-archived"
    actor = $ArchivedBy
    details = $Reason
}

Save-AIOfficeEvent -Event $event -Path $eventPath

$archiveFolder = Join-Path ".\workspace\calendar\archive" $EventId

if (-not (Test-Path -LiteralPath $archiveFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
}

Copy-Item -Path (Join-Path $eventFolder "*") -Destination $archiveFolder -Recurse -Force

& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Calendar event archived successfully." -ForegroundColor Green
Write-Host "Event ID:     $EventId"
Write-Host "Archive copy: $archiveFolder"
'@

New-SafeFile ".\scripts\calendar\Archive-AIOfficeEvent.ps1" $archiveEventScript

$agendaScript = @'
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
'@

New-SafeFile ".\scripts\calendar\Generate-AIOfficeAgenda.ps1" $agendaScript

$weeklyPlannerScript = @'
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
    "{0} through {1}" -f
    $weekStart.ToString("MMMM d, yyyy"),
    $weekEnd.ToString("MMMM d, yyyy")
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
        "Capacity: {0:N1}h | Scheduled: {1:N1}h | Remaining: {2:N1}h" -f
        ($capacity / 60),
        ($scheduledMinutes / 60),
        ($remaining / 60)
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
'@

New-SafeFile ".\scripts\calendar\Generate-AIOfficeWeeklyPlan.ps1" $weeklyPlannerScript

$expandRecurringScript = @'
param(
    [int]$DaysAhead = 90,
    [string]$CreatedBy = "calendar-engine"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$eventFiles = Get-ChildItem `
    -Path ".\workspace\calendar\events" `
    -Filter "event.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

$windowEnd = (Get-Date).Date.AddDays($DaysAhead)
$createdCount = 0

foreach ($eventFile in $eventFiles) {
    $event = Get-Content -LiteralPath $eventFile.FullName -Raw | ConvertFrom-Json

    if ($event.recurrence.frequency -eq "none") {
        continue
    }

    if ($event.tags -contains "recurrence-instance") {
        continue
    }

    $originalStart = ConvertTo-AIOfficeDateTime -Value ([string]$event.start_at)
    $originalEnd = ConvertTo-AIOfficeDateTime -Value ([string]$event.end_at)
    $duration = $originalEnd - $originalStart
    $nextStart = $originalStart
    $generated = 0
    $maximumCount = $event.recurrence.count
    $until = $null

    if (-not [string]::IsNullOrWhiteSpace([string]$event.recurrence.until)) {
        $until = ConvertTo-AIOfficeDateTime -Value ([string]$event.recurrence.until)
    }

    while ($true) {
        switch ([string]$event.recurrence.frequency) {
            "daily" {
                $nextStart = $nextStart.AddDays([int]$event.recurrence.interval)
            }
            "weekly" {
                $nextStart = $nextStart.AddDays(7 * [int]$event.recurrence.interval)
            }
            "monthly" {
                $nextStart = $nextStart.AddMonths([int]$event.recurrence.interval)
            }
            "yearly" {
                $nextStart = $nextStart.AddYears([int]$event.recurrence.interval)
            }
        }

        $generated++

        if ($nextStart -gt $windowEnd) {
            break
        }

        if ($null -ne $until -and $nextStart -gt $until) {
            break
        }

        if ($null -ne $maximumCount -and $generated -ge [int]$maximumCount) {
            break
        }

        $instanceKey = "recurrence:{0}:{1}" -f $event.event_id, $nextStart.ToString("yyyyMMddHHmm")
        $existing = Get-ChildItem `
            -Path ".\workspace\calendar\events" `
            -Filter "event.json" `
            -File `
            -Recurse |
            ForEach-Object {
                try {
                    Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
                }
                catch {
                    $null
                }
            } |
            Where-Object {
                $null -ne $_ -and @($_.tags) -contains $instanceKey
            }

        if ($existing) {
            continue
        }

        $newTags = @($event.tags) + @(
            "recurrence-instance",
            $instanceKey,
            ("parent:{0}" -f $event.event_id)
        )

        $parameters = @{
            Title = [string]$event.title
            Description = [string]$event.description
            EventType = [string]$event.event_type
            Priority = [string]$event.priority
            StartAt = $nextStart.ToString("yyyy-MM-ddTHH:mm:ss")
            EndAt = $nextStart.Add($duration).ToString("yyyy-MM-ddTHH:mm:ss")
            EstimatedMinutes = [int]$event.estimated_minutes
            Timezone = [string]$event.timezone
            OwnerAgent = [string]$event.owner_agent
            CreatedBy = $CreatedBy
            Location = [string]$event.location
            Recurrence = "none"
            ProjectId = [string]$event.links.project_id
            WorkflowId = [string]$event.links.workflow_id
            TaskId = [string]$event.links.task_id
            KnowledgeIds = @($event.links.knowledge_ids)
            Tags = $newTags
        }

        if ($event.all_day) {
            $parameters.AllDay = $true
        }

        & ".\scripts\calendar\New-AIOfficeEvent.ps1" @parameters | Out-Null
        $createdCount++
    }
}

Write-Host "Recurring event expansion complete: $createdCount event(s) created." -ForegroundColor Green
'@

New-SafeFile ".\scripts\calendar\Expand-AIOfficeRecurringEvents.ps1" $expandRecurringScript

$workflowSyncScript = @'
param(
    [string]$WorkflowId = "",
    [string]$CreatedBy = "calendar-engine",
    [switch]$IncludeCompletedTasks
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$workflowRoot = ".\workspace\workflows"

if (-not (Test-Path -LiteralPath $workflowRoot -PathType Container)) {
    throw "Package 9 workflow folder was not found."
}

$workflowFiles = Get-ChildItem `
    -Path $workflowRoot `
    -Filter "workflow.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

if (-not [string]::IsNullOrWhiteSpace($WorkflowId)) {
    $workflowFiles = @(
        $workflowFiles | Where-Object {
            $_.Directory.Name -eq $WorkflowId
        }
    )
}

$createdCount = 0

foreach ($workflowFile in $workflowFiles) {
    $workflow = Get-Content -LiteralPath $workflowFile.FullName -Raw | ConvertFrom-Json

    foreach ($task in @($workflow.tasks)) {
        if (-not $IncludeCompletedTasks -and $task.status -eq "completed") {
            continue
        }

        $dueValue = $null

        foreach ($propertyName in @("due_at", "due_date", "deadline")) {
            if (
                $task.PSObject.Properties.Name -contains $propertyName -and
                -not [string]::IsNullOrWhiteSpace([string]$task.$propertyName)
            ) {
                $dueValue = [string]$task.$propertyName
                break
            }
        }

        if ([string]::IsNullOrWhiteSpace($dueValue)) {
            continue
        }

        $taskId = if (
            $task.PSObject.Properties.Name -contains "task_id"
        ) {
            [string]$task.task_id
        }
        else {
            [string]$task.id
        }

        $existing = & ".\scripts\calendar\Search-AIOfficeEvents.ps1" `
            -Query $taskId `
            -IncludeCompleted `
            -IncludeCancelled 2>$null |
            Out-String

        if ($existing -match [regex]::Escape($taskId)) {
            continue
        }

        $title = if (
            $task.PSObject.Properties.Name -contains "title"
        ) {
            [string]$task.title
        }
        else {
            "Workflow task $taskId"
        }

        $priority = if (
            $task.PSObject.Properties.Name -contains "priority" -and
            [string]$task.priority -in @("critical", "high", "normal", "low")
        ) {
            [string]$task.priority
        }
        else {
            "normal"
        }

        & ".\scripts\calendar\New-AIOfficeEvent.ps1" `
            -Title $title `
            -Description ("Generated from workflow {0}, task {1}." -f $workflow.workflow_id, $taskId) `
            -EventType "deadline" `
            -Priority $priority `
            -StartAt $dueValue `
            -EstimatedMinutes 30 `
            -OwnerAgent ([string]$task.owner_agent) `
            -CreatedBy $CreatedBy `
            -WorkflowId ([string]$workflow.workflow_id) `
            -TaskId $taskId `
            -Tags @("workflow-sync", $taskId) |
            Out-Null

        $createdCount++
    }
}

Write-Host "Workflow calendar sync complete: $createdCount event(s) created." -ForegroundColor Green
'@

New-SafeFile ".\scripts\calendar\Sync-AIOfficeWorkflowCalendar.ps1" $workflowSyncScript

$testCalendarScript = @'
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
'@

New-SafeFile ".\scripts\calendar\Test-AIOfficeCalendar.ps1" $testCalendarScript

$calendarGuide = @'
# AI Office Calendar and Scheduling Guide

Status: Active
Owner: Chief of Staff
Version: 1.0.0

## Purpose

Package 11 gives AI Office time awareness through calendar events, deadlines, recurring schedules, daily agendas, weekly planning, workload estimates, urgency scoring, and workflow integration.

## Event Storage

Calendar events are stored in:

workspace/calendar/events/EVT-ID/event.json

Generated agendas are stored in:

workspace/calendar/agendas/

Weekly reports are stored in:

workspace/calendar/reports/

Archived copies are stored in:

workspace/calendar/archive/

## Create an Event

powershell -ExecutionPolicy Bypass -File scripts/calendar/New-AIOfficeEvent.ps1 -Title "Review Google Ads" -StartAt "2026-08-03 09:00" -EndAt "2026-08-03 10:00" -EventType task -Priority high -Tags analytics,google-ads

## Create a Deadline

powershell -ExecutionPolicy Bypass -File scripts/calendar/New-AIOfficeEvent.ps1 -Title "Elite campaign due" -StartAt "2026-08-07 17:00" -EventType deadline -Priority critical -EstimatedMinutes 120

## Create a Recurring Event

powershell -ExecutionPolicy Bypass -File scripts/calendar/New-AIOfficeEvent.ps1 -Title "Weekly planning" -StartAt "2026-08-03 08:00" -EventType review -Priority high -Recurrence weekly -RecurrenceInterval 1 -Tags planning,weekly

Then generate future instances:

powershell -ExecutionPolicy Bypass -File scripts/calendar/Expand-AIOfficeRecurringEvents.ps1 -DaysAhead 90

## Search Events

powershell -ExecutionPolicy Bypass -File scripts/calendar/Search-AIOfficeEvents.ps1 -Query "Google Ads"

powershell -ExecutionPolicy Bypass -File scripts/calendar/Search-AIOfficeEvents.ps1 -Priority high -From "2026-08-01" -To "2026-08-31"

## Show an Event

powershell -ExecutionPolicy Bypass -File scripts/calendar/Show-AIOfficeEvent.ps1 -EventId EVT-20260731-0001 -ShowHistory

## Update an Event

powershell -ExecutionPolicy Bypass -File scripts/calendar/Update-AIOfficeEvent.ps1 -EventId EVT-20260731-0001 -Priority critical -ChangeNote "Deadline became urgent."

## Complete an Event

powershell -ExecutionPolicy Bypass -File scripts/calendar/Complete-AIOfficeEvent.ps1 -EventId EVT-20260731-0001 -ActualMinutes 45

## Archive an Event

powershell -ExecutionPolicy Bypass -File scripts/calendar/Archive-AIOfficeEvent.ps1 -EventId EVT-20260731-0001 -Reason "No longer needed."

## Daily Agenda

powershell -ExecutionPolicy Bypass -File scripts/calendar/Generate-AIOfficeAgenda.ps1

For a specific date:

powershell -ExecutionPolicy Bypass -File scripts/calendar/Generate-AIOfficeAgenda.ps1 -Date "2026-08-03" -SaveReport

## Weekly Plan

powershell -ExecutionPolicy Bypass -File scripts/calendar/Generate-AIOfficeWeeklyPlan.ps1 -WeekOf "2026-08-03" -SaveReport

## Workflow Integration

Package 11 can create calendar deadlines from Package 9 workflow tasks that contain due_at, due_date, or deadline fields.

powershell -ExecutionPolicy Bypass -File scripts/calendar/Sync-AIOfficeWorkflowCalendar.ps1

For one workflow:

powershell -ExecutionPolicy Bypass -File scripts/calendar/Sync-AIOfficeWorkflowCalendar.ps1 -WorkflowId WORKFLOW-ID

## Validation

powershell -ExecutionPolicy Bypass -File scripts/calendar/Test-AIOfficeCalendar.ps1

Expected result:

All calendar management checks passed.
'@

New-SafeFile ".\docs\Calendar-Scheduling-Guide.md" $calendarGuide

Write-Host ""
Write-Host "Validating Package 11 JSON..." -ForegroundColor Cyan
Write-Host ""

$jsonFiles = @(
    ".\config\calendar\calendar-policy.json",
    ".\config\calendar\calendar-event-schema.json",
    ".\workspace\calendar\calendar-index.json",
    ".\workspace\templates\calendar-event-template.json"
)

$jsonErrors = 0

foreach ($jsonFile in $jsonFiles) {
    try {
        Get-Content -LiteralPath $jsonFile -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID  ] $jsonFile" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID] $jsonFile" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $jsonErrors++
    }
}

Write-Host ""

if ($jsonErrors -gt 0) {
    Write-Host "Package 11 completed with validation errors." -ForegroundColor Red
    Write-Host "Do not commit until those errors are corrected." -ForegroundColor Yellow
    exit 1
}

$installerDestination = Join-Path `
    $expectedRepository `
    "Installers\AI-Office-Package-11-Install.ps1"

try {
    $currentInstaller = $MyInvocation.MyCommand.Path

    if (
        -not [string]::IsNullOrWhiteSpace($currentInstaller) -and
        (Resolve-Path $currentInstaller).Path -ne $installerDestination
    ) {
        Copy-Item `
            -LiteralPath $currentInstaller `
            -Destination $installerDestination `
            -Force

        Write-Host "[COPIED ] Installer saved to $installerDestination" -ForegroundColor Green
    }
}
catch {
    Write-Warning "Package installed, but the installer could not be copied into the Installers folder."
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " AI Office Package 11 Complete" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created:" -ForegroundColor White
Write-Host "  Calendar policies and event schema"
Write-Host "  Calendar event storage and searchable index"
Write-Host "  Event creation, display, search, and update commands"
Write-Host "  Completion and archiving commands"
Write-Host "  Priority and urgency scoring"
Write-Host "  Daily agenda generation"
Write-Host "  Weekly capacity planning"
Write-Host "  Recurring event expansion"
Write-Host "  Package 9 workflow calendar synchronization"
Write-Host "  Documentation and validation"
Write-Host ""
Write-Host "All Package 11 JSON files passed validation." -ForegroundColor Green
