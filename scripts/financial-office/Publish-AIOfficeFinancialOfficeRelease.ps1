param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$CertificationFile = Get-ChildItem `
    -LiteralPath "E:\AI\AI-Office\workspace\financial-office\certification" `
    -Filter "CERT-FIN-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $CertificationFile) {
    throw "No Financial Office certification record was found."
}

$Certification = Get-Content -LiteralPath $CertificationFile.FullName -Raw | ConvertFrom-Json

if ([string]$Certification.status -ne "certified") {
    throw "Latest Financial Office certification is not certified."
}

$ManifestPath = "E:\AI\AI-Office\config\financial-office\release-manifest.json"
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

    $Version.version = "1.7.0"
    $Version.release_name = "Personal Financial Office"
    $Version.status = "released"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.8 Business Incubator"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8
}

$ProjectStatusPath = "E:\AI\AI-Office\config\project-status.json"

if (Test-Path -LiteralPath $ProjectStatusPath -PathType Leaf) {
    $Project = Get-Content -LiteralPath $ProjectStatusPath -Raw | ConvertFrom-Json

    $Project.version = "1.7.0"
    $Project.current_phase = "Preparing Business Incubator"
    $Project.current_milestone = "Personal Financial Office Certified"
    $Project.release_status = "operational"
    $Project.next_release = "1.8.0"
    $Project.next_milestone = "Business Incubator"

    $Project |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $ProjectStatusPath -Encoding UTF8
}

Write-Host ""
Write-Host "AI Office v1.7 Personal Financial Office released." -ForegroundColor Green
