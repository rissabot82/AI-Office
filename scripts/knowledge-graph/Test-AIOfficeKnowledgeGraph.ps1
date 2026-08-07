param(
    [switch]$PublishRelease
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.5 Knowledge Graph and Reasoning..." `
    -ForegroundColor Cyan
Write-Host ""

$Certification = & "E:\AI\AI-Office\scripts\knowledge-graph\Certify-AIOfficeKnowledgeGraph.ps1"

if ([string]$Certification.status -ne "certified") {
    Write-Host "Knowledge Graph certification failed." -ForegroundColor Red
    exit 1
}

if ($PublishRelease) {
    & "E:\AI\AI-Office\scripts\knowledge-graph\Publish-AIOfficeKnowledgeGraphRelease.ps1"
}

Write-Host ""
Write-Host "All AI Office v1.5 Knowledge Graph and Reasoning checks passed." `
    -ForegroundColor Green
