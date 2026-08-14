param()
$ErrorActionPreference="Stop"
$Path="E:\AI\AI-Office\README.md"
$Content=Get-Content -LiteralPath $Path -Raw
$Content=$Content.Replace('**Current Version:** v2.3.0 — Conversational AI Office','**Current Version:** v2.4.0 — Discord Mobile Operations')

if($Content -notmatch '## AI Office v2\.4 — Discord Mobile Operations'){
$Section=@'

---

## AI Office v2.4 — Discord Mobile Operations

**Status:** Certified / Operational  
**Version:** 2.4.0  
**Remote Interface:** Discord

AI Office now has a functioning remote conversational interface through a private Discord server.

### Discord Capabilities

- Secure bot-token environment configuration
- Explicit guild/channel/user allowlisting
- Persistent Discord-to-AI-Office conversation sessions
- Remote conversation through the AI Office Chief of Staff
- Explicit department routing
- `/new`, `/session`, `/status`, `/history`, `/help`
- `/departments` and `/department <name> <request>`
- Background Discord worker
- Worker lifecycle and operations monitoring
- Safety and audit tooling
- Live activation readiness gate
- Local Ollama inference through the existing hybrid runtime

### Next Milestone

**Data and Connector Layer**

---
'@
Add-Content -LiteralPath $Path -Value $Section -Encoding UTF8
}

Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
Write-Host "README updated for AI Office v2.4." -ForegroundColor Green
