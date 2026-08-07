param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Errors = New-Object System.Collections.Generic.List[string]

$Required = @(
    ".\dashboard\public\operations-integrations-module.js",
    ".\dashboard\public\operations-integrations-module.css",
    ".\scripts\operations-integrations\New-AIOfficeOperationsDashboardSnapshot.ps1",
    ".\scripts\operations-integrations\Install-AIOfficeOperationsDashboardIntegration.ps1"
)

foreach ($Item in $Required) {
    if (-not (Test-Path -LiteralPath $Item -PathType Leaf)) {
        $Errors.Add("Missing dashboard component: $Item")
    }
}

try {
    $Snapshot = & ".\scripts\operations-integrations\New-AIOfficeOperationsDashboardSnapshot.ps1"
    if ($null -eq $Snapshot.metrics) { throw "Dashboard snapshot metrics missing." }
    if (-not (Test-Path -LiteralPath ".\dashboard\data\operations-integrations.json" -PathType Leaf)) {
        throw "Dashboard snapshot file was not written."
    }
    Write-Host "[SNAPSHOT OK] Operations dashboard data generated." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    foreach ($ErrorMessage in $Errors) {
        Write-Host "[DASHBOARD ERR] $ErrorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "All AI Office v1.9 Operations Dashboard checks passed." -ForegroundColor Green
