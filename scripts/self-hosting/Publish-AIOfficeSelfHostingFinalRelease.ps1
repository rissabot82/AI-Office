param()

$ErrorActionPreference = "Stop"

$Certification = & "E:\AI\AI-Office\scripts\self-hosting\Certify-AIOfficeSelfHostingFinal.ps1"

if ([string]$Certification.status -ne "certified") {
    throw "Self-Hosted AI Office final certification failed."
}

$ManifestPath = "E:\AI\AI-Office\config\self-hosting\final-release-manifest.json"
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$Manifest.status = "released"
$Manifest | Add-Member -NotePropertyName "released_at" -NotePropertyValue ((Get-Date).ToString("o")) -Force
$Manifest | Add-Member -NotePropertyName "certification_id" -NotePropertyValue ([string]$Certification.certification_id) -Force
$Manifest | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8

$VersionPath = "E:\AI\AI-Office\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw | ConvertFrom-Json
    $Version.version = "2.2.0"
    $Version.release_name = "Self-Hosted AI Office"
    $Version.status = "released"
    $Version | Add-Member -NotePropertyName "released_at" -NotePropertyValue ((Get-Date).ToString("o")) -Force
    $Version.next_planned_milestone = "Discord Mobile Task Intake and Remote Operations"
    $Version | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $VersionPath -Encoding UTF8
}

& "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeSelfHostingFinalDashboardSnapshot.ps1" | Out-Null

Write-Host ""
Write-Host "AI Office v2.2 Self-Hosted AI Office released." -ForegroundColor Green

return $Certification
