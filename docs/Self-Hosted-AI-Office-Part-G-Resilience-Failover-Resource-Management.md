# Self-Hosted AI Office Part G — Resilience, Failover and Resource Management

Part G adds the operational safety layer around self-hosted inference.

It provides:

- CPU, RAM, GPU, and disk monitoring
- Ollama service health
- OpenClaw Gateway health
- Dashboard health
- Local-to-cloud failover records
- Ollama recovery
- Dashboard recovery
- Resource threshold warnings
- Recovery records
- Resilience status reporting

Validation:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeResilience.ps1"
```

Expected:

```text
All Self-Hosted AI Office Part G Resilience, Failover and Resource Management checks passed.
```
