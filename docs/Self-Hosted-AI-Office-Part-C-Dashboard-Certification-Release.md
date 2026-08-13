# Self-Hosted AI Office Part C — Dashboard, Certification, and Release

Part C completes the first self-hosting milestone.

It adds:
- Self-hosting dashboard snapshot
- Local inference dashboard module
- Full Part A + Part B certification
- Release manifest
- Release publisher
- AI Office v2.1 version transition

Run:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHosting.ps1" `
    -PublishRelease
```
