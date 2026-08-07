param()

$ErrorActionPreference = "Stop"

$Snapshot = & "E:\AI\AI-Office\scripts\autonomous-enterprise\New-AIOfficeEnterpriseDashboardSnapshot.ps1"

$Required = @(
    "E:\AI\AI-Office\dashboard\public\data\autonomous-enterprise.json",
    "E:\AI\AI-Office\dashboard\public\autonomous-enterprise-module.js",
    "E:\AI\AI-Office\dashboard\public\autonomous-enterprise-module.css",
    "E:\AI\AI-Office\dashboard\public\index.html"
)

foreach ($Path in $Required) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Dashboard component missing: $Path"
    }
}

$Html = Get-Content -LiteralPath "E:\AI\AI-Office\dashboard\public\index.html" -Raw

if ($Html -notmatch 'autonomous-enterprise-module') {
    throw "Autonomous AI Enterprise dashboard host not found."
}

if ($Html -notmatch 'autonomous-enterprise-module\.js') {
    throw "Autonomous AI Enterprise JavaScript integration not found."
}

Write-Host "[SNAPSHOT OK] Enterprise dashboard data generated." -ForegroundColor Green
Write-Host "[INTEGRATION OK] Enterprise dashboard module installed." -ForegroundColor Green
Write-Host "All AI Office v2.0 Enterprise Dashboard checks passed." -ForegroundColor Green

return $Snapshot
