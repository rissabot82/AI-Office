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
