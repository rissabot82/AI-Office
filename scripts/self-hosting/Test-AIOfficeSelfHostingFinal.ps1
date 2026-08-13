param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Testing AI Office v2.2 Self-Hosted AI Office..." -ForegroundColor Cyan
Write-Host ""

if ($PublishRelease) {
    $Certification = & "E:\AI\AI-Office\scripts\self-hosting\Publish-AIOfficeSelfHostingFinalRelease.ps1"
}
else {
    $Certification = & "E:\AI\AI-Office\scripts\self-hosting\Certify-AIOfficeSelfHostingFinal.ps1"
}

$Certification | Format-List

if ([string]$Certification.status -ne "certified") {
    throw "Self-Hosted AI Office final certification failed."
}

Write-Host ""
Write-Host "All AI Office v2.2 Self-Hosted AI Office checks passed." -ForegroundColor Green
