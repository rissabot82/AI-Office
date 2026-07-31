param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\certification" `
        -Filter "CERT-AWF-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Autonomous Workflows certification record exists."
}

$Certification = Read-AIOfficeAutonomousWorkflowJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Autonomous Workflows certification did not pass."
}

$ManifestPath = ".\config\autonomous-workflows\release-manifest.json"
$Manifest = Read-AIOfficeAutonomousWorkflowJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Autonomous Workflows release manifest could not be loaded."
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

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Autonomous Workflows"
    version = "1.4.0"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.5 Knowledge Graph and Reasoning"
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $ReleaseRecord `
    -Path (
        ".\workspace\autonomous-workflows\releases\AI-Office-v1.4-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        ".json"
    )

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeAutonomousWorkflowJson -Path $IdentityPath
    $Identity.version = "1.4.0"
    $Identity.codename = "Autonomous Workflows"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeAutonomousWorkflowJson -Path $VersionPath
    $Version.version = "1.4.0"
    $Version.release_name = "Autonomous Workflows"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.3.0"
    $Version.next_planned_milestone = "1.5 Knowledge Graph and Reasoning"

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.4 Autonomous Workflows release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
