# AI Office Package 13 — Automation Engine

Package 13 adds an event-driven automation engine to AI Office.

## Capabilities

- Rule-based triggers and actions
- Queued automation events
- Conditions
- Priority-ordered rule execution
- Execution logs
- Dry-run mode
- Duplicate suppression
- Maximum-depth loop protection
- Rule enable/disable controls
- Event archiving
- Dashboard and report actions
- PowerShell component execution
- Downstream event queueing

## Create a rule

```powershell
$actions = @(
    @{
        type = "write_log"
        message = "Workflow approval automation executed."
    }
) | ConvertTo-Json -Depth 10 -Compress

powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\New-AIOfficeAutomationRule.ps1" `
    -Name "Approved workflow handler" `
    -TriggerType "workflow_approved" `
    -ActionsJson $actions
```

## Queue an event

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Queue-AIOfficeAutomationEvent.ps1" `
    -TriggerType "workflow_approved" `
    -Source "workflow-engine" `
    -PayloadJson '{"workflow_id":"WF-1001","status":"approved"}'
```

## Process the queue

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1"
```

Dry-run mode:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1" `
    -DryRun
```

## Disable or enable a rule

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Disable-AIOfficeAutomationRule.ps1" `
    -RuleId "AUT-EXAMPLE"
```

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Enable-AIOfficeAutomationRule.ps1" `
    -RuleId "AUT-EXAMPLE"
```

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Test-AIOfficeAutomation.ps1"
```

Expected result:

```text
All automation engine checks passed.
```

## Scheduling

Windows Task Scheduler can call:

```text
scripts\automation\Invoke-AIOfficeAutomationEngine.ps1
```

on a recurring schedule. Package 15 will connect scheduling, executive routines, reporting, and startup behavior into the final operating system.
