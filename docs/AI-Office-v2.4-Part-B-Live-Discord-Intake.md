# AI Office v2.4 Part B — Live Discord Intake

Part B wires Discord into the existing AI Office v2.3 conversational runtime.

It adds:

- Discord REST API client
- Bot identity validation
- Secure token retrieval from environment
- Explicit guild/channel/user allowlist configuration
- Discord-to-conversation session creation
- Live inbound message handling
- AI Office conversational execution
- Discord response posting
- Event persistence

## Token setup

Create a Discord bot in the Discord Developer Portal, then store the token as a Windows user environment variable:

```powershell
[Environment]::SetEnvironmentVariable(
    "AI_OFFICE_DISCORD_BOT_TOKEN",
    "YOUR_BOT_TOKEN",
    "User"
)

$env:AI_OFFICE_DISCORD_BOT_TOKEN = "YOUR_BOT_TOKEN"
```

Do not place the token in the repository.

## Validate architecture before token setup

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordLiveRuntime.ps1" `
    -SkipLiveApi
```

After the token is configured, run without `-SkipLiveApi`.
