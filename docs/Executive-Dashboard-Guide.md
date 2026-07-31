# AI Office Executive Dashboard

Package 12 adds a consolidated executive dashboard across the AI Office repository.

## Core capabilities

- Creates timestamped operational snapshots
- Summarizes workflows, approvals, calendar events, knowledge records, and system health
- Calculates a 0–100 operational health score
- Detects overdue work, blocked workflows, pending approvals, stale knowledge, invalid JSON, and missing components
- Produces console dashboards
- Exports standalone HTML reports
- Maintains a searchable snapshot index
- Archives old snapshots

## Create a snapshot

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1"
```

## Show the latest dashboard

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1"
```

Create a new snapshot immediately before displaying it:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1" `
    -CreateNew
```

## Export an HTML dashboard

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1" `
    -CreateNew `
    -Open
```

Reports are stored in:

```text
workspace\dashboard\reports
```

## Archive old snapshots

Preview:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Archive-AIOfficeDashboardSnapshots.ps1" `
    -OlderThanDays 90 `
    -WhatIf
```

Archive:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Archive-AIOfficeDashboardSnapshots.ps1" `
    -OlderThanDays 90
```

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Test-AIOfficeExecutiveDashboard.ps1"
```

Expected result:

```text
All executive dashboard checks passed.
```

## Data-source behavior

The dashboard automatically checks for existing AI Office indexes. Missing optional data sources are treated as empty rather than fatal. Invalid JSON and missing Package 12 components are treated as system risks.
