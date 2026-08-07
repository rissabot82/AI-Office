param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.8 Business Incubator..." -ForegroundColor Cyan
Write-Host ""

$Certification = & "E:\AI\AI-Office\scripts\business-incubator\Certify-AIOfficeBusinessIncubator.ps1"

$Certification | Format-List `
    certification_id,
    version,
    release_name,
    certified_at,
    status,
    passed_checks,
    failed_checks,
    checks

if ([string]$Certification.status -ne "certified") {
    Write-Host ""
    Write-Host "Business Incubator certification failed." -ForegroundColor Red
    exit 1
}

if ($PublishRelease) {
    & "E:\AI\AI-Office\scripts\business-incubator\Publish-AIOfficeBusinessIncubatorRelease.ps1"
}

Write-Host ""
Write-Host "All AI Office v1.8 Business Incubator checks passed." -ForegroundColor Green
