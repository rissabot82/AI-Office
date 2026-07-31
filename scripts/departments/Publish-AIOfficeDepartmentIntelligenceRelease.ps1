param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\departments\certification" `
        -Filter "CERT-DEPT-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Department Intelligence certification record exists."
}

$Certification = Read-AIOfficeDepartmentJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Department Intelligence certification did not pass."
}

$ManifestPath = ".\config\departments\release-manifest.json"
$Manifest = Read-AIOfficeDepartmentJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Department Intelligence release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"
$Manifest.released_at = $ReleasedAt
$Manifest.certification_id = [string]$Certification.certification_id

Write-AIOfficeDepartmentJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Department Intelligence"
    version = "1.2.0"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.3 Long-Term Memory"
}

$ReleasePath = Join-Path `
    ".\workspace\departments\releases" `
    ("AI-Office-v1.2-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeDepartmentJson `
    -Value $ReleaseRecord `
    -Path $ReleasePath

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeDepartmentJson -Path $IdentityPath
    $Identity.version = "1.2.0"
    $Identity.codename = "Department Intelligence"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeDepartmentJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeDepartmentJson -Path $VersionPath
    $Version.version = "1.2.0"
    $Version.release_name = "Department Intelligence"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.1.4"
    $Version.next_planned_milestone = "1.3 Long-Term Memory"

    Write-AIOfficeDepartmentJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.2 Department Intelligence release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
