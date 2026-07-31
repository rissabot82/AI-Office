# AI Office v1.2 Part B — Department Inbox and Work Intake

Part B connects each department to the AI Office Message Bus and turns handoffs into persistent department work items.

## Added

- Department inbox policy
- Capability-based intake classification
- Work-item creation
- Department inbox processing
- Processed and failed inbox records
- Work search
- Message completion and failure handling
- Department index updates
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1"
```

Expected result:

```text
All AI Office v1.2 Part B Department Inbox and Work Intake checks passed.
```

## Process a department inbox

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" `
    -Department "marketing" `
    -Limit 10
```

## Search department work

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Search-AIOfficeDepartmentWork.ps1" `
    -Department "marketing"
```

## Next

Part C will add department planning, execution modes, cross-department handoffs, result publication, and Chief of Staff reporting.
