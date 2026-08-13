param()

$ErrorActionPreference = "Stop"

$Certification = & "E:\AI\AI-Office\scripts\self-hosting\Certify-AIOfficeSelfHosting.ps1"

if ([string]$Certification.status -ne "certified") {
    throw "Self-Hosted AI Office certification failed."
}

$ManifestPath = "E:\AI\AI-Office\config\self-hosting\release-manifest.json"
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$Manifest.status = "released"
$Manifest | Add-Member -NotePropertyName "released_at" -NotePropertyValue ((Get-Date).ToString("o")) -Force
$Manifest | Add-Member -NotePropertyName "certification_id" -NotePropertyValue ([string]$Certification.certification_id) -Force
$Manifest | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8

$VersionPath = "E:\AI\AI-Office\config\identity\version.json"
if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw | ConvertFrom-Json
    $Version.version = "2.1.0"
    $Version.release_name = "Self-Hosted AI Office Foundation"
    $Version.status = "released"
    $Version | Add-Member -NotePropertyName "released_at" -NotePropertyValue ((Get-Date).ToString("o")) -Force
    $Version.next_planned_milestone = "Self-Hosting Part D Model Routing and Hybrid Execution"
    $Version | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $VersionPath -Encoding UTF8
}

& "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeSelfHostingDashboardSnapshot.ps1" | Out-Null

Write-Host ""
Write-Host "AI Office v2.1 Self-Hosted AI Office Foundation released." -ForegroundColor Green

return $Certification
