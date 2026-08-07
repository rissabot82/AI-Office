param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\business-incubator\certification" `
        -Filter "CERT-BIZ-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Business Incubator certification record was found."
}

$Certification = Get-Content -LiteralPath $CertificationFiles[0].FullName -Raw | ConvertFrom-Json

if ([string]$Certification.status -ne "certified") {
    throw "Latest Business Incubator certification is not certified."
}

$ManifestPath = "E:\AI\AI-Office\config\business-incubator\release-manifest.json"
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

$Manifest.status = "released"
$Manifest | Add-Member -NotePropertyName "released_at" -NotePropertyValue (Get-Date).ToString("o") -Force
$Manifest | Add-Member -NotePropertyName "certification_id" -NotePropertyValue ([string]$Certification.certification_id) -Force

$Manifest | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8

$VersionPath = "E:\AI\AI-Office\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw | ConvertFrom-Json
    $Version.version = "1.8.0"
    $Version.release_name = "Business Incubator"
    $Version.status = "released"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "2.0 Autonomous AI Enterprise"
    $Version | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $VersionPath -Encoding UTF8
}

Write-Host "AI Office v1.8 Business Incubator released." -ForegroundColor Green
