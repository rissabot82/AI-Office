# AI Office Dashboard

## Start and open

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1" `
    -OpenBrowser
```

Dashboard URL:

```text
http://127.0.0.1:18880/
```

## Stop

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1"
```

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Test-AIOfficeDashboard.ps1"
```

## Start automatically at Windows logon

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1"
```

The initial dashboard is read-only and displays:

- OpenClaw, bridge, memory, and workflow status
- Message queue counts
- Department activity
- Recent memory
- Recent autonomous runs
- Approval and failure counts
