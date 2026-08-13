param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Testing Self-Hosted AI Office Foundation..." -ForegroundColor Cyan
Write-Host ""

if ($PublishRelease) {
    $Certification = & "E:\AI\AI-Office\scripts\self-hosting\Publish-AIOfficeSelfHostingRelease.ps1"
}
else {
    $Certification = & "E:\AI\AI-Office\scripts\self-hosting\Certify-AIOfficeSelfHosting.ps1"
}

$Certification | Format-List

if ([string]$Certification.status -ne "certified") {
    throw "Self-Hosted AI Office certification failed."
}

Write-Host ""
Write-Host "All Self-Hosted AI Office Foundation checks passed." -ForegroundColor Green
