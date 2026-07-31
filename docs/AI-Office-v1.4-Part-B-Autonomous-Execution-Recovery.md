# AI Office v1.4 Part B — Autonomous Execution and Recovery

Part B turns persistent workflow plans into executable, approval-aware, checkpointed, restart-safe runs.

## Added

- Autonomous step execution
- Dependency checks
- Chief of Staff steps
- Department dispatch
- Message Bus dispatch
- OpenClaw Bridge dispatch
- Memory recall
- Wait steps
- Report steps
- Human approval gates
- Step results
- Before/after checkpoints
- Failure records
- Retry records
- Run recovery
- Restart-safe continuation
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousExecution.ps1"
```

Expected result:

```text
All AI Office v1.4 Part B Autonomous Execution and Recovery checks passed.
```

## Execute a run

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1" `
    -RunId "RUN-..." `
    -MaximumSteps 25
```

## Approve a waiting step

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Set-AIOfficeAutonomousApproval.ps1" `
    -RunId "RUN-..." `
    -StepId "STEP-..." `
    -Status "approved" `
    -Decision "Proceed."
```

## Recover runs after restart

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1"
```

## Next

Part C will add background scheduling, autonomous worker cycles, workflow monitoring, executive reporting, full certification, and v1.4 release publication.
