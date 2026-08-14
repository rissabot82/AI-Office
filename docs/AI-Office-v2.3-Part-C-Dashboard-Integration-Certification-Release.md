# AI Office v2.3 Part C — Dashboard Integration, Certification and Release

Part C completes v2.3 by integrating conversational status into the dashboard, certifying Parts A and B, and publishing the release.

Run:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\conversational-office\Test-AIOfficeConversationalOffice.ps1" `
    -PublishRelease
```

Expected:

```text
Conversational AI Office certification: certified | 4 passed, 0 failed
AI Office v2.3 Conversational AI Office released.
All AI Office v2.3 Conversational AI Office checks passed.
```
