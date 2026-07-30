$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

Write-Host ""
Write-Host "Testing AI Office review system..." -ForegroundColor Cyan
Write-Host ""

$errorsFound = 0

$jsonFiles = @(
    ".\config\review\review-policy.json",
    ".\config\review\review-checks.json",
    ".\config\review\approval-values.json",
    ".\workspace\templates\review-record-template.json",
    ".\workspace\templates\approval-record-template.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        Write-Host "[INVALID   ] $file" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $errorsFound++
    }
}

$requiredScripts = @(
    ".\scripts\review\Review-AIOfficeTask.ps1",
    ".\scripts\review\Approve-AIOfficeTask.ps1",
    ".\scripts\review\Show-AIOfficeReview.ps1"
)

foreach ($script in $requiredScripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING     ] $script" -ForegroundColor Red
        $errorsFound++
    }
}

$policy = Get-Content `
    -LiteralPath ".\config\review\review-policy.json" `
    -Raw |
    ConvertFrom-Json

if (
    [int]$policy.minimum_passing_score -ge 0 -and
    [int]$policy.minimum_passing_score -le 100
) {
    Write-Host "[VALID SCORE ] Minimum passing score" -ForegroundColor Green
}
else {
    Write-Host "[BAD SCORE   ] Minimum passing score" -ForegroundColor Red
    $errorsFound++
}

$checks = Get-Content `
    -LiteralPath ".\config\review\review-checks.json" `
    -Raw |
    ConvertFrom-Json

if (@($checks.checks).Count -gt 0) {
    Write-Host "[CHECKS FOUND] $(@($checks.checks).Count) review checks" -ForegroundColor Green
}
else {
    Write-Host "[NO CHECKS   ] Review checks are missing" -ForegroundColor Red
    $errorsFound++
}

Write-Host ""

if ($errorsFound -eq 0) {
    Write-Host "All review system checks passed." -ForegroundColor Green
}
else {
    Write-Host "$errorsFound review-system error or errors were found." -ForegroundColor Red
    exit 1
}
