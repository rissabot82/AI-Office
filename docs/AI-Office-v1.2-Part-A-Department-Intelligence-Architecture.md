# AI Office v1.2 Part A — Department Intelligence Architecture

Part A creates the formal operating structure for nine intelligent AI Office departments.

## Departments installed

- Marketing
- Creative
- Website
- Analytics
- Finance
- Business Incubator
- Side Hustles
- YouTube Studio
- Personal Assistant

## Added

- Department Intelligence governance
- Department profiles
- Capability registries
- Responsibilities
- KPIs
- Department workspaces
- Department status indexes
- Global Department Intelligence index
- Department lookup
- Capability validation
- Full architecture validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1"
```

Expected result:

```text
All AI Office v1.2 Part A Department Intelligence Architecture checks passed.
```

## Show department status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Show-AIOfficeDepartmentStatus.ps1"
```

## Inspect one department

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\departments\Get-AIOfficeDepartment.ps1" `
    -Department "marketing"
```

## Next

Part B will add department inboxes, work-item intake, capability-based acceptance, planning, and Chief of Staff handoffs.
