param()

$ErrorActionPreference = "Stop"

$Certification = & "E:\AI\AI-Office\scripts\autonomous-enterprise\Certify-AIOfficeAutonomousEnterprise.ps1"

if ([string]$Certification.status -ne "certified") {
    throw "Autonomous AI Enterprise certification failed."
}

$VersionPath = "E:\AI\AI-Office\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw | ConvertFrom-Json

    $Version.version = "2.0.0"
    $Version.release_name = "Autonomous AI Enterprise"
    $Version.status = "released"
    $Version.released_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "Self-Hosted AI Office"

    $Version |
        ConvertTo-Json -Depth 50 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8
}

$ManifestPath = "E:\AI\AI-Office\config\autonomous-enterprise\release-manifest.json"
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$Manifest.status = "released"
$Manifest | Add-Member -NotePropertyName "released_at" -NotePropertyValue ((Get-Date).ToString("o")) -Force
$Manifest | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8

& "E:\AI\AI-Office\scripts\autonomous-enterprise\New-AIOfficeEnterpriseDashboardSnapshot.ps1" | Out-Null

Write-Host ""
Write-Host "AI Office v2.0 Autonomous AI Enterprise released." -ForegroundColor Green

return $Certification
