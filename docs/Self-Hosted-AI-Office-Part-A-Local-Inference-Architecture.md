# Self-Hosted AI Office Part A — Local Inference Architecture

Part A establishes the self-hosting control plane.

It adds:

- Local inference providers
- Local model profiles
- Model-routing rules
- Hardware inventory
- Local-first privacy routing
- Cloud fallback policy
- Self-hosting indexes
- Validation tooling

The default local provider architecture is prepared for Ollama on:

`http://127.0.0.1:11434`

Part B will install and validate the actual local inference runtime, connect it to AI Office,
inventory available models, and perform the first real local model execution test.

Validation:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingArchitecture.ps1"
```
