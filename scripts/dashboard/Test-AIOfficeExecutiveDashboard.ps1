param()

$ErrorActionPreference = "Stop"

$root = Resolve-Path (
    Join-Path $PSScriptRoot "..\.."
)

Set-Location $root.Path

Write-Host ""
Write-Host "Testing AI Office executive dashboard..." `
    -ForegroundColor Cyan
Write-Host ""

$errors = New-Object System.Collections.Generic.List[string]

$jsonFiles = @(
    ".\config\dashboard\dashboard-policy.json",
    ".\config\dashboard\executive-dashboard-schema.json",
    ".\workspace\dashboard\dashboard-index.json",
    ".\workspace\templates\executive-dashboard-template.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $file" `
            -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $file" `
            -ForegroundColor Red

        $errors.Add(
            "Invalid JSON: " +
            $file +
            " - " +
            $_.Exception.Message
        )
    }
}

$requiredScripts = @(
    ".\scripts\dashboard\AIOfficeDashboard.Common.ps1",
    ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1",
    ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1",
    ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1",
    ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1",
    ".\scripts\dashboard\Archive-AIOfficeDashboardSnapshots.ps1",
    ".\scripts\dashboard\Test-AIOfficeExecutiveDashboard.ps1"
)

foreach ($script in $requiredScripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" `
            -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $script" `
            -ForegroundColor Red

        $errors.Add(
            "Missing script: " +
            $script
        )
    }
}

try {
    $snapshot = & `
        ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" `
        -PassThru

    if (
        $null -ne $snapshot -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$snapshot.snapshot_id
        ) -and
        [int]$snapshot.overall_health.score -ge 0 -and
        [int]$snapshot.overall_health.score -le 100
    ) {
        Write-Host (
            "[SNAPSHOT OK] " +
            [string]$snapshot.snapshot_id +
            " | Health " +
            [string]$snapshot.overall_health.score +
            "/100"
        ) -ForegroundColor Green
    }
    else {
        throw "Snapshot did not contain expected values."
    }
}
catch {
    Write-Host "[SNAPSHOT ERR] Snapshot generation failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $errors.Add(
        "Snapshot generation failed: " +
        $_.Exception.Message
    )
}

try {
    $index = & `
        ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1"

    if (
        $null -ne $index -and
        [int]$index.snapshot_count -gt 0
    ) {
        Write-Host (
            "[INDEX OK   ] " +
            [string]$index.snapshot_count +
            " dashboard snapshot(s)"
        ) -ForegroundColor Green
    }
    else {
        throw "Dashboard index did not contain a snapshot."
    }
}
catch {
    Write-Host "[INDEX ERR  ] Dashboard indexing failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $errors.Add(
        "Dashboard indexing failed: " +
        $_.Exception.Message
    )
}

try {
    $reportPath = & `
        ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1"

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$reportPath
        ) -and
        (Test-Path -LiteralPath $reportPath -PathType Leaf)
    ) {
        Write-Host (
            "[EXPORT OK  ] " +
            [string]$reportPath
        ) -ForegroundColor Green
    }
    else {
        throw "HTML report was not created."
    }
}
catch {
    Write-Host "[EXPORT ERR ] HTML report generation failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $errors.Add(
        "HTML report generation failed: " +
        $_.Exception.Message
    )
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $errors.Count.ToString() +
        " executive dashboard error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All executive dashboard checks passed." `
    -ForegroundColor Green
