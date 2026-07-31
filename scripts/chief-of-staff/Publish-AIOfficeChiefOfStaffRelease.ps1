param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\certification" `
        -Filter "CERT-COS-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Chief of Staff certification record exists."
}

$Certification = Read-AIOfficeChiefOfStaffJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Chief of Staff certification did not pass."
}

$ManifestPath = ".\config\chief-of-staff\release-manifest.json"
$Manifest = Read-AIOfficeChiefOfStaffJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Chief of Staff release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"
$Manifest.released_at = $ReleasedAt
$Manifest.certification_id = [string]$Certification.certification_id

Write-AIOfficeChiefOfStaffJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Chief of Staff Integration"
    version = "1.1.4"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.2 Department Intelligence"
}

$ReleasePath = Join-Path `
    ".\workspace\chief-of-staff\releases" `
    ("AI-Office-v1.1.4-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $ReleaseRecord `
    -Path $ReleasePath

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeChiefOfStaffJson -Path $IdentityPath
    $Identity.version = "1.1.4"
    $Identity.codename = "Chief of Staff"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeChiefOfStaffJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeChiefOfStaffJson -Path $VersionPath
    $Version.version = "1.1.4"
    $Version.release_name = "Chief of Staff Integration"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.1.3"
    $Version.next_planned_milestone = "1.2 Department Intelligence"

    Write-AIOfficeChiefOfStaffJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.1.4 Chief of Staff release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
