param()
$ErrorActionPreference="Stop"

$Certification=& "E:\AI\AI-Office\scripts\discord-office\Certify-AIOfficeDiscordMobileOperations.ps1"
if([string]$Certification.status -ne "certified"){throw "AI Office v2.4 Discord Mobile Operations certification failed."}

$ManifestPath="E:\AI\AI-Office\config\discord-office\release-manifest.json"
$Manifest=Get-Content -LiteralPath $ManifestPath -Raw|ConvertFrom-Json
$Manifest.status="released"
$Manifest|Add-Member -NotePropertyName released_at -NotePropertyValue ((Get-Date).ToString("o")) -Force
$Manifest|Add-Member -NotePropertyName certification_id -NotePropertyValue ([string]$Certification.certification_id) -Force
$Manifest|ConvertTo-Json -Depth 100|Set-Content -LiteralPath $ManifestPath -Encoding UTF8

$VersionPath="E:\AI\AI-Office\config\identity\version.json"
$Version=Get-Content -LiteralPath $VersionPath -Raw|ConvertFrom-Json
$Version.version="2.4.0"
$Version.release_name="Discord Mobile Operations"
$Version.status="released"
$Version.next_planned_milestone="Data and Connector Layer"
$Version|Add-Member -NotePropertyName released_at -NotePropertyValue ((Get-Date).ToString("o")) -Force
$Version|ConvertTo-Json -Depth 100|Set-Content -LiteralPath $VersionPath -Encoding UTF8

& "E:\AI\AI-Office\scripts\discord-office\Update-AIOfficeV24Readme.ps1"

Write-Host ""
Write-Host "AI Office v2.4 Discord Mobile Operations released." -ForegroundColor Green
return $Certification
