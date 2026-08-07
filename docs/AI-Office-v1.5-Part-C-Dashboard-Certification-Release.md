# AI Office v1.5 Part C — Dashboard, Certification, and Release

Part C completes AI Office v1.5.

It adds:

- Knowledge Graph dashboard snapshot
- Knowledge Graph dashboard module
- Entity, relationship, inference, contradiction, and decision-score status
- Full v1.5 certification
- Release manifest
- Release publication tooling

Install dashboard integration:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\knowledge-graph\Install-AIOfficeKnowledgeGraphDashboardIntegration.ps1"
```

Validate dashboard integration:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\knowledge-graph\Test-AIOfficeKnowledgeGraphDashboard.ps1"
```

Run full v1.5 certification:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\knowledge-graph\Test-AIOfficeKnowledgeGraph.ps1"
```

Certify and publish:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\knowledge-graph\Test-AIOfficeKnowledgeGraph.ps1" `
    -PublishRelease
```
