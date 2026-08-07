param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.7 Personal Financial Office..." -ForegroundColor Cyan
Write-Host ""

$CertificationOutput = & powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File "E:\AI\AI-Office\scripts\financial-office\Certify-AIOfficeFinancialOffice.ps1" 2>&1

$CertificationExitCode = $LASTEXITCODE
$CertificationText = ($CertificationOutput | Out-String).Trim()

Write-Host $CertificationText

if ($CertificationExitCode -ne 0) {
    Write-Host ""
    Write-Host "Financial Office certification failed." -ForegroundColor Red
    exit 1
}

if ($PublishRelease) {
    & "E:\AI\AI-Office\scripts\financial-office\Publish-AIOfficeFinancialOfficeRelease.ps1"
}

Write-Host ""
Write-Host "All AI Office v1.7 Personal Financial Office checks passed." -ForegroundColor Green
