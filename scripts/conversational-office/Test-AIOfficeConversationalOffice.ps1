param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Testing AI Office v2.3 Conversational AI Office..." -ForegroundColor Cyan
Write-Host ""

if ($PublishRelease) {
    $Certification = & "E:\AI\AI-Office\scripts\conversational-office\Publish-AIOfficeConversationalOfficeRelease.ps1"
}
else {
    $Certification = & "E:\AI\AI-Office\scripts\conversational-office\Certify-AIOfficeConversationalOffice.ps1"
}

$Certification | Format-List

if ([string]$Certification.status -ne "certified") {
    throw "Conversational AI Office certification failed."
}

Write-Host ""
Write-Host "All AI Office v2.3 Conversational AI Office checks passed." -ForegroundColor Green
