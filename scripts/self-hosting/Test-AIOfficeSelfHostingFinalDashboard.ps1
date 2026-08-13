param()

$ErrorActionPreference = "Stop"

$Snapshot = & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeSelfHostingFinalDashboardSnapshot.ps1"

$Required = @(
    "E:\AI\AI-Office\dashboard\public\data\self-hosting-final.json",
    "E:\AI\AI-Office\dashboard\public\self-hosting-final-module.js",
    "E:\AI\AI-Office\dashboard\public\self-hosting-final-module.css",
    "E:\AI\AI-Office\dashboard\public\index.html"
)

foreach ($Path in $Required) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Final self-hosting dashboard component missing: $Path"
    }
}

if ([string]$Snapshot.overall_status -ne "operational") {
    throw "Self-hosted AI Office final dashboard is not operational."
}

Write-Host "[FINAL SNAPSHOT OK] Self-hosting final dashboard data generated." -ForegroundColor Green
Write-Host "[FINAL DASHBOARD OK] Final self-hosting dashboard integration passed." -ForegroundColor Green
return $Snapshot
