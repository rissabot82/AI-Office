# AI Office v1.7 Part C — Dashboard, Certification, and Release

Part C completes AI Office v1.7.

It adds:

- Personal Financial Office dashboard snapshot
- Financial dashboard module
- Goal and debt visibility
- Side-hustle performance
- Financial recommendations
- Forecast and paycheck-plan status
- Full v1.7 certification
- Release publication tooling

Validate dashboard:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\financial-office\Test-AIOfficeFinancialDashboard.ps1"
```

Run full certification:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\financial-office\Test-AIOfficeFinancialOffice.ps1"
```

Publish:

```powershell
powershell -ExecutionPolicy Bypass -File `
    "E:\AI\AI-Office\scripts\financial-office\Test-AIOfficeFinancialOffice.ps1" `
    -PublishRelease
```
