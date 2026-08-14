# AI Office v2.4 Part C — Persistent Sessions and Commands

Part C makes Discord conversations manageable across multiple messages and reconnects.

Included commands:

- `/new`
- `/session`
- `/status`
- `/history [count]`
- `/help`

Discord user/channel mappings now preserve the active AI Office conversation session until explicitly replaced.

Validation:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordPersistentSessions.ps1"
```

Expected:

```text
All AI Office v2.4 Part C Persistent Sessions and Commands checks passed.
```
