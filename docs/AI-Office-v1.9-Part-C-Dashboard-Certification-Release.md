# AI Office v1.9 Part C — Dashboard, Certification, and Release

Run the full release:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\operations-integrations\Test-AIOfficeOperationsIntegrations.ps1" `
    -PublishRelease
```

Expected certification:

```text
Operations and Integrations certification: certified | 4 passed, 0 failed
AI Office v1.9 Operations and Integrations released.
All AI Office v1.9 Operations and Integrations checks passed.
```

The release command commits the repository, creates tag `v1.9.0`, and pushes `main` and the release tag.
Use `-SkipGit` if release validation is needed without publishing Git changes.
