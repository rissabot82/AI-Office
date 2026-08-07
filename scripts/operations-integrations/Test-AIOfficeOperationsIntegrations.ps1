param(
    [switch]$PublishRelease,
    [switch]$SkipGit
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.9 Operations and Integrations..." -ForegroundColor Cyan
Write-Host ""

if ($PublishRelease) {
    $Certification = & "E:\AI\AI-Office\scripts\operations-integrations\Publish-AIOfficeOperationsIntegrationsRelease.ps1" `
        -SkipGit:$SkipGit
}
else {
    $Certification = & "E:\AI\AI-Office\scripts\operations-integrations\Certify-AIOfficeOperationsIntegrations.ps1"
}

$Certification | Format-List `
    certification_id,version,release_name,certified_at,status,passed_checks,failed_checks,checks

if ([string]$Certification.status -ne "certified") {
    Write-Host ""
    Write-Host "Operations and Integrations certification failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.9 Operations and Integrations checks passed." -ForegroundColor Green
