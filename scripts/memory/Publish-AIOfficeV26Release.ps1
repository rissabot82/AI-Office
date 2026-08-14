param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Latest = Get-ChildItem ".\workspace\memory\certifications\CERT-MEMORY-*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $Latest) {
    throw "No v2.6 memory certification found."
}

$Cert = Get-Content $Latest.FullName -Raw | ConvertFrom-Json

if ([string]$Cert.status -ne "passed" -or [int]$Cert.failed_checks -ne 0) {
    throw "Latest v2.6 memory certification is not release-ready."
}

$ManifestPath = ".\config\memory\release-manifest.json"
$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$Manifest.status = "released"
$Manifest.components.final_integration = "complete"
$Manifest | Add-Member certification_id ([string]$Cert.certification_id) -Force
$Manifest | Add-Member released_at ((Get-Date).ToString("o")) -Force
$Manifest | ConvertTo-Json -Depth 30 | Set-Content $ManifestPath -Encoding UTF8

$VersionPath = ".\config\identity\version.json"
if (Test-Path $VersionPath) {
    $Version = Get-Content $VersionPath -Raw | ConvertFrom-Json
    $Version.version = "2.6.0"
    $Version.release_name = "Memory & Context Integration"
    $Version.status = "released"
    $Version | Add-Member previous_version "2.5.1" -Force
    $Version | Add-Member released_at ((Get-Date).ToString("o")) -Force
    $Version | ConvertTo-Json -Depth 30 | Set-Content $VersionPath -Encoding UTF8
}

Write-Host "AI Office v2.6.0 Memory & Context Integration RELEASED." -ForegroundColor Green
Write-Host ("Certification: " + $Cert.certification_id) -ForegroundColor Cyan
