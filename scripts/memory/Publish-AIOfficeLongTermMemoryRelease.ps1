param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\memory\certification" `
        -Filter "CERT-MEM-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Long-Term Memory certification record exists."
}

$Certification = Read-AIOfficeMemoryJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Long-Term Memory certification did not pass."
}

$ManifestPath = ".\config\memory\release-manifest.json"
$Manifest = Read-AIOfficeMemoryJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Long-Term Memory release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"

foreach ($Property in @(
    @{ Name = "released_at"; Value = $ReleasedAt },
    @{
        Name = "certification_id"
        Value = [string]$Certification.certification_id
    }
)) {
    if ($null -ne $Manifest.PSObject.Properties[$Property.Name]) {
        $Manifest.($Property.Name) = $Property.Value
    }
    else {
        $Manifest | Add-Member `
            -MemberType NoteProperty `
            -Name $Property.Name `
            -Value $Property.Value
    }
}

Write-AIOfficeMemoryJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Long-Term Memory"
    version = "1.3.0"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.4 Autonomous Workflows"
}

Write-AIOfficeMemoryJson `
    -Value $ReleaseRecord `
    -Path (
        ".\workspace\memory\releases\AI-Office-v1.3-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        ".json"
    )

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeMemoryJson -Path $IdentityPath
    $Identity.version = "1.3.0"
    $Identity.codename = "Long-Term Memory"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeMemoryJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeMemoryJson -Path $VersionPath
    $Version.version = "1.3.0"
    $Version.release_name = "Long-Term Memory"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.2.0"
    $Version.next_planned_milestone = "1.4 Autonomous Workflows"

    Write-AIOfficeMemoryJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.3 Long-Term Memory release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord

