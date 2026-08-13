# Self-Hosted AI Office Part D — Model Routing and Hybrid Execution

Part D adds the decision layer between local Ollama inference and cloud/OpenClaw execution.

It provides:

- Privacy-aware routing
- Complexity-aware routing
- Task-type routing
- Explicit execution modes
- Local-only protection for private context
- Local-preferred execution
- Cloud-preferred execution
- Cloud fallback readiness
- Routing decision records
- Hybrid execution result records

Validation:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeHybridRouting.ps1"
```

Expected:

```text
All Self-Hosted AI Office Part D Model Routing and Hybrid Execution checks passed.
```
