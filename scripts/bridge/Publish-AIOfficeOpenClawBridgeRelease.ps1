param(
    [switch]$RequireLiveCertification
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\certification" `
        -Filter "CERT-BRIDGE-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No OpenClaw Bridge certification record exists."
}

$Certification = Read-AIOfficeBridgeJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest OpenClaw Bridge certification did not pass."
}

if ($RequireLiveCertification -and
    [string]$Certification.mode -ne "live") {
    throw "Latest certification is not a live certification."
}

$ManifestPath = ".\config\bridge\release-manifest.json"
$Manifest = Read-AIOfficeBridgeJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Bridge release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"
$Manifest.released_at = $ReleasedAt
$Manifest.certification_id = [string]$Certification.certification_id
$Manifest.certification_mode = [string]$Certification.mode

Write-AIOfficeBridgeJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "OpenClaw Bridge"
    version = "1.1.3"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    certification_mode = [string]$Certification.mode
    next_milestone = "1.1.4 Chief of Staff Integration"
}

$ReleasePath = Join-Path `
    ".\workspace\bridge\releases" `
    ("AI-Office-v1.1.3-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeBridgeJson `
    -Value $ReleaseRecord `
    -Path $ReleasePath

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeBridgeJson -Path $IdentityPath
    $Identity.version = "1.1.3"
    $Identity.codename = "OpenClaw Bridge"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeBridgeJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeBridgeJson -Path $VersionPath
    $Version.version = "1.1.3"
    $Version.release_name = "OpenClaw Bridge"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.1.2"
    $Version.next_planned_milestone = "1.1.4 Chief of Staff Integration"

    Write-AIOfficeBridgeJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.1.3 OpenClaw Bridge release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
