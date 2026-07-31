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
