param()

$ErrorActionPreference = "Stop"

$Snapshot = & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeSelfHostingDashboardSnapshot.ps1"

$Required = @(
    "E:\AI\AI-Office\dashboard\public\data\self-hosting.json",
    "E:\AI\AI-Office\dashboard\public\self-hosting-module.js",
    "E:\AI\AI-Office\dashboard\public\self-hosting-module.css",
    "E:\AI\AI-Office\dashboard\public\index.html"
)

foreach ($Path in $Required) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Self-hosting dashboard component missing: $Path"
    }
}

$Html = Get-Content -LiteralPath "E:\AI\AI-Office\dashboard\public\index.html" -Raw

if ($Html -notmatch 'self-hosting-module') { throw "Self-hosting dashboard host not found." }
if ([string]$Snapshot.runtime.health -ne "healthy") { throw "Local inference runtime is not healthy." }

Write-Host "[SNAPSHOT OK] Self-hosting dashboard data generated." -ForegroundColor Green
Write-Host "[INTEGRATION OK] Self-hosting dashboard module installed." -ForegroundColor Green
Write-Host "[RUNTIME OK] Local inference health is healthy." -ForegroundColor Green
Write-Host "All Self-Hosted AI Office Dashboard checks passed." -ForegroundColor Green

return $Snapshot
