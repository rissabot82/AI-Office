param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Testing AI Office v2.0 Autonomous AI Enterprise..." -ForegroundColor Cyan
Write-Host ""

if ($PublishRelease) {
    $Certification = & "E:\AI\AI-Office\scripts\autonomous-enterprise\Publish-AIOfficeAutonomousEnterpriseRelease.ps1"
}
else {
    $Certification = & "E:\AI\AI-Office\scripts\autonomous-enterprise\Certify-AIOfficeAutonomousEnterprise.ps1"
}

$Certification | Format-List

if ([string]$Certification.status -ne "certified") {
    throw "Autonomous AI Enterprise certification failed."
}

Write-Host ""
Write-Host "All AI Office v2.0 Autonomous AI Enterprise checks passed." -ForegroundColor Green
