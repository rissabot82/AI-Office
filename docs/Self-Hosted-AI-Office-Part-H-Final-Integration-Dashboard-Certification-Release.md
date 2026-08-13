# Self-Hosted AI Office Part H — Final Integration, Dashboard, Certification and Release

Part H completes the self-hosting build and publishes AI Office v2.2.

Run:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingFinal.ps1" `
    -PublishRelease
```

Expected:

```text
Self-Hosted AI Office final certification: certified | 8 passed, 0 failed
AI Office v2.2 Self-Hosted AI Office released.
All AI Office v2.2 Self-Hosted AI Office checks passed.
```
