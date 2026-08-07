# AI Office v1.8 Part C — Dashboard, Certification, and Release

Install the dashboard integration:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\business-incubator\Install-AIOfficeBusinessIncubatorDashboardIntegration.ps1"
```

Test dashboard support:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\business-incubator\Test-AIOfficeBusinessIncubatorDashboard.ps1"
```

Certify and release v1.8:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\business-incubator\Test-AIOfficeBusinessIncubator.ps1" `
    -PublishRelease
```

Expected certification:

```text
Business Incubator certification: certified | 4 passed, 0 failed
All AI Office v1.8 Business Incubator checks passed.
```
