# AI Office Startup and Health

Start AI Office and open the dashboard:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\health\Start-AIOffice.ps1" `
    -OpenDashboard
```

Run a health check:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\health\Get-AIOfficeSystemHealth.ps1"
```

The token is read from the OpenClaw WSL configuration for the current process and is never printed.
