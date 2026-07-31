# AI Office v1.1.1 — Identity System

This milestone gives AI Office a formal identity, mission, version, capability catalog, and standard identity envelope.

## Show the identity

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\identity\Show-AIOfficeIdentity.ps1"
```

## Export the identity

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\identity\Export-AIOfficeIdentity.ps1"
```

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\identity\Test-AIOfficeIdentity.ps1"
```

Expected result:

```text
All AI Office v1.1.1 Identity System checks passed.
```

## Next milestone

AI Office v1.1.2 will add the internal Message Bus.
