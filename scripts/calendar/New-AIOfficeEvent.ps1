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
