param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$CertificationFile = Get-ChildItem `
    -LiteralPath "E:\AI\AI-Office\workspace\multi-agent\certification" `
    -Filter "CERT-MA-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $CertificationFile) {
    throw "No Multi-Agent certification record was found."
}

$Certification = Get-Content `
    -LiteralPath $CertificationFile.FullName `
    -Raw |
    ConvertFrom-Json

if ([string]$Certification.status -ne "certified") {
    throw "Latest Multi-Agent certification is not certified."
}

$ManifestPath = "E:\AI\AI-Office\config\multi-agent\release-manifest.json"
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

if ($null -eq $Manifest.PSObject.Properties["released_at"]) {
    $Manifest |
        Add-Member `
            -NotePropertyName "released_at" `
            -NotePropertyValue (Get-Date).ToString("o")
}
else {
    $Manifest.released_at = (Get-Date).ToString("o")
}

$Manifest.status = "released"

$Manifest |
    ConvertTo-Json -Depth 40 |
    Set-Content -LiteralPath $ManifestPath -Encoding UTF8

$VersionPath = "E:\AI\AI-Office\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw | ConvertFrom-Json

    $Version.version = "1.6.0"
    $Version.release_name = "Multi-Agent Collaboration"
    $Version.status = "released"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.7 Personal Financial Office"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8
}

$ProjectStatusPath = "E:\AI\AI-Office\config\project-status.json"

if (Test-Path -LiteralPath $ProjectStatusPath -PathType Leaf) {
    $Project = Get-Content -LiteralPath $ProjectStatusPath -Raw | ConvertFrom-Json

    $Project.version = "1.6.0"
    $Project.current_phase = "Preparing Personal Financial Office"
    $Project.current_milestone = "Multi-Agent Collaboration Certified"
    $Project.release_status = "operational"
    $Project.next_release = "1.7.0"
    $Project.next_milestone = "Personal Financial Office"

    $Project |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $ProjectStatusPath -Encoding UTF8
}

Write-Host ""
Write-Host "AI Office v1.6 Multi-Agent Collaboration released." `
    -ForegroundColor Green
