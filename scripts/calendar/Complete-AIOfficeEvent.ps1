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
