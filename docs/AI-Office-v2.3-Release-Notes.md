# AI Office v2.3 — Conversational AI Office

AI Office v2.3 introduces a functioning conversational front door.

Included:

- Persistent conversation sessions
- User and assistant message history
- Conversation turns
- Chief-of-Staff-first intake
- Context assembly
- Intelligent local model selection
- Live Ollama responses
- Interactive PowerShell chat
- Conversational dashboard
- Full certification and release tooling

Interactive chat:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\conversational-office\Start-AIOfficeConversation.ps1"
```

Next milestone: Discord Mobile Operations.
