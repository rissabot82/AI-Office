# Self-Hosted AI Office Part F — Local Model Fleet and Specialized Models

Part F expands local inference from one general model into a small specialized fleet.

Default fleet:

- General: `qwen2.5:3b`
- Code: `qwen2.5-coder:3b`
- Reasoning (optional): `deepseek-r1:1.5b`

The installer pulls required models, optionally pulls the reasoning model, registers capabilities,
and creates a fleet snapshot.

Because local storage and VRAM are finite, the initial fleet intentionally stays small.

Validation:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeLocalModelFleet.ps1"
```

Expected:

```text
All Self-Hosted AI Office Part F Local Model Fleet and Specialized Models checks passed.
```
