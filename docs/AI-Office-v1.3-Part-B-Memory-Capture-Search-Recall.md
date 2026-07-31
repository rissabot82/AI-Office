# AI Office v1.3 Part B — Memory Capture, Search, and Recall

Part B makes Long-Term Memory usable across AI Office.

## Added

- Manual memory creation
- JSON source import
- Search by text, scope, department, type, project, entity, status, and confidence
- Access tracking
- Duplicate detection
- Related-memory discovery
- Context packet generation
- Capture records
- Recall history support
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1"
```

Expected result:

```text
All AI Office v1.3 Part B Memory Capture, Search, and Recall checks passed.
```

## Create memory

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\New-AIOfficeMemory.ps1" `
    -Scope "department" `
    -Department "marketing" `
    -MemoryType "lesson" `
    -Title "Successful dealership campaign structure" `
    -Summary "Reusable campaign launch sequence." `
    -ContentJson '{"steps":["offer","creative","website","tracking","reporting"]}' `
    -SourceJson '{"type":"manual","project":"Elite Auto Sales"}' `
    -Confidence 0.90 `
    -Tags @("campaign","dealership") `
    -Entities @("Elite Auto Sales") `
    -Projects @("Elite Marketing")
```

## Search memory

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\Search-AIOfficeMemory.ps1" `
    -Query "campaign" `
    -Department "marketing"
```

## Build a Chief of Staff context packet

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" `
    -Query "campaign" `
    -RequestedBy "chief-of-staff" `
    -Limit 10
```

## Next

Part C will add feedback, correction, promotion, demotion, staleness review, conflict handling, memory health, certification, and release publication.
