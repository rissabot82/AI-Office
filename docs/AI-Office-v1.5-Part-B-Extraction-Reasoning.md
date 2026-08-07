# AI Office v1.5 Part B — Extraction and Reasoning

Part B adds:

- Entity resolution and deduplication
- Long-term memory import into the graph
- Graph neighborhood traversal
- Contradiction scanning
- Context ranking
- Inference records
- Decision scoring

Validation:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\knowledge-graph\Test-AIOfficeKnowledgeReasoning.ps1"
```

Expected:

```text
All AI Office v1.5 Part B Extraction and Reasoning checks passed.
```
