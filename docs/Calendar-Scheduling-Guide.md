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
