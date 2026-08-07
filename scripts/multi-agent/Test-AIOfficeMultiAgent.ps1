param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.6 Multi-Agent Collaboration..." `
    -ForegroundColor Cyan
Write-Host ""

$CertificationOutput = & powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File "E:\AI\AI-Office\scripts\multi-agent\Certify-AIOfficeMultiAgent.ps1" 2>&1

$CertificationExitCode = $LASTEXITCODE
$CertificationText = ($CertificationOutput | Out-String).Trim()

Write-Host $CertificationText

if ($CertificationExitCode -ne 0) {
    Write-Host ""
    Write-Host "Multi-Agent certification failed." -ForegroundColor Red
    exit 1
}

if ($PublishRelease) {
    & "E:\AI\AI-Office\scripts\multi-agent\Publish-AIOfficeMultiAgentRelease.ps1"
}

Write-Host ""
Write-Host "All AI Office v1.6 Multi-Agent Collaboration checks passed." `
    -ForegroundColor Green
