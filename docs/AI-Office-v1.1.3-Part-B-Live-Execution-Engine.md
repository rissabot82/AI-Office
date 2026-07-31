# AI Office v1.1.3 Part B — Live Execution Engine

Part B adds the authenticated OpenClaw Gateway WebSocket transport and the first live execution path.

## Added

- Protocol v4 WebSocket transport
- Gateway challenge handling
- Token authentication through `OPENCLAW_GATEWAY_TOKEN`
- Operator read/write scopes
- Generic OpenClaw RPC client
- Authenticated Gateway health check
- Live `agent` and `agent.wait` execution flow
- Message Bus consumer
- Bridge execution records
- Message completion and failure updates
- Dry-run and authenticated validation

## Security

The Gateway token is never stored in the repository. It must be supplied through the current PowerShell process:

```powershell
$env:OPENCLAW_GATEWAY_TOKEN = "PASTE_TOKEN_HERE"
```

Do not commit or save the token in a script.

## Standard validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1"
```

## Authenticated validation

After setting the token in the same PowerShell window:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1" `
    -AuthenticatedConnectionTest
```

## Test Gateway connection only

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" `
    -Authenticated
```

## Next

Part C will normalize results, capture artifacts, publish execution-result messages, and manage failed execution recovery.
