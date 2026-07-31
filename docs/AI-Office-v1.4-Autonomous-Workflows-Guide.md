# AI Office v1.4 — Autonomous Workflows

AI Office v1.4 adds persistent, restart-safe, human-supervised autonomous workflow execution.

## Delivered

### Part A — Architecture
- Executive goals
- Autonomous plans
- Persistent runs
- Dependencies
- Approval policy
- Retry policy
- Checkpoint policy
- Recovery architecture

### Part B — Execution and Recovery
- Step execution
- Memory recall
- Department dispatch
- Message Bus dispatch
- OpenClaw dispatch
- Human approval gates
- Checkpoints
- Retries
- Failures
- Restart recovery

### Part C — Runtime and Release
- Worker cycles
- Background processing
- Monitoring
- Stale-run warnings
- Executive reports
- Scheduled-task installation
- Complete certification
- Release publication

## Complete validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflows.ps1"
```

Expected ending:

```text
All AI Office v1.4 Autonomous Workflows checks passed.
AI Office v1.4 Autonomous Workflows is operational.
```

## Publish release

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Publish-AIOfficeAutonomousWorkflowsRelease.ps1"
```

## Install background worker

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Install-AIOfficeAutonomousWorkerTask.ps1" `
    -IntervalMinutes 15
```

## Run worker manually

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousWorkerCycle.ps1"
```

## Generate monitoring report

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Get-AIOfficeAutonomousWorkflowMonitoring.ps1"
```

## Next milestone

AI Office v1.5 will introduce Knowledge Graph and Reasoning.
