# AI Office v2.3 Part B — Live Conversational Runtime

Part B connects persistent conversation sessions to real local AI inference.

Included:

- Chief-of-Staff system prompt
- Conversation context assembly
- Lightweight task detection
- Intelligent local model selection
- Live Ollama response generation
- User/assistant message persistence
- Completed turn records
- One-shot message command
- Interactive PowerShell conversation shell

After validation, start an interactive AI Office conversation with:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\conversational-office\Start-AIOfficeConversation.ps1"
```

Validation:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\conversational-office\Test-AIOfficeConversationRuntime.ps1"
```

Expected:

```text
All AI Office v2.3 Part B Live Conversational Runtime checks passed.
```
