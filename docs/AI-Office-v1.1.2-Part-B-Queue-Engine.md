# AI Office v1.1.2 Part B — Queue Engine

Part B adds durable queue movement and message lifecycle control.

## Added

- Message lookup
- Queue movement
- Policy-based routing
- Priority-aware receiving
- Message claiming
- Acknowledgement
- Completion
- Failure handling
- Delivery-attempt tracking
- Message searching
- Queue-engine validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Test-AIOfficeQueueEngine.ps1"
```

Expected result:

```text
All AI Office v1.1.2 Part B Queue Engine checks passed.
```

## Next

Part C adds retry scheduling, dead-letter handling, maintenance, archival, and processor controls.
