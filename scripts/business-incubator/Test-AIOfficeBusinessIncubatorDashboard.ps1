param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($Path in @(
    "E:\AI\AI-Office\dashboard\public\business-incubator-module.js",
    "E:\AI\AI-Office\dashboard\public\business-incubator-module.css",
    "E:\AI\AI-Office\scripts\business-incubator\New-AIOfficeBusinessIncubatorDashboardSnapshot.ps1"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Write-Host "[FOUND] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Path" -ForegroundColor Red
        $Errors.Add("Missing: $Path")
    }
}

try {
    $Snapshot = & "E:\AI\AI-Office\scripts\business-incubator\New-AIOfficeBusinessIncubatorDashboardSnapshot.ps1"
    if ($null -eq $Snapshot) {
        throw "Dashboard snapshot returned no data."
    }
    Write-Host "[SNAPSHOT OK] ideas=$($Snapshot.summary.ideas)" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[SNAPSHOT ERR] $($_.Exception.Message)" -ForegroundColor Red
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Business Incubator dashboard error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.8 Business Incubator dashboard checks passed." -ForegroundColor Green
