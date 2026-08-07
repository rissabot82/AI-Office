param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Checks = New-Object System.Collections.Generic.List[object]

function Add-BusinessCertificationCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

try {
    $OutputA = & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File "E:\AI\AI-Office\scripts\business-incubator\Test-AIOfficeBusinessIncubatorArchitecture.ps1" 2>&1

    $ExitCodeA = $LASTEXITCODE
    $TextA = ($OutputA | Out-String).Trim()

    $PassedA = (
        $ExitCodeA -eq 0 -and
        $TextA -like "*All AI Office v1.8 Part A Business Incubator Architecture checks passed.*"
    )

    Add-BusinessCertificationCheck `
        -Name "Part A Business Incubator Architecture" `
        -Passed $PassedA `
        -Details $(if ($PassedA) { "Validation passed." } else { $TextA })
}
catch {
    Add-BusinessCertificationCheck `
        -Name "Part A Business Incubator Architecture" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    $OutputB = & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File "E:\AI\AI-Office\scripts\business-incubator\Test-AIOfficeVenturePlanning.ps1" 2>&1

    $ExitCodeB = $LASTEXITCODE
    $TextB = ($OutputB | Out-String).Trim()

    $PassedB = (
        $ExitCodeB -eq 0 -and
        $TextB -like "*All AI Office v1.8 Part B Validation and Venture Planning checks passed.*"
    )

    Add-BusinessCertificationCheck `
        -Name "Part B Validation and Venture Planning" `
        -Passed $PassedB `
        -Details $(if ($PassedB) { "Validation passed." } else { $TextB })
}
catch {
    Add-BusinessCertificationCheck `
        -Name "Part B Validation and Venture Planning" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    $Snapshot = & "E:\AI\AI-Office\scripts\business-incubator\New-AIOfficeBusinessIncubatorDashboardSnapshot.ps1"
    $SnapshotPath = "E:\AI\AI-Office\dashboard\runtime\business-incubator-snapshot.json"
    $PassedSnapshot = (Test-Path -LiteralPath $SnapshotPath -PathType Leaf) -and ($null -ne $Snapshot)

    Add-BusinessCertificationCheck `
        -Name "Business Incubator Dashboard Snapshot" `
        -Passed $PassedSnapshot `
        -Details ("ideas=" + [string]$Snapshot.summary.ideas + "; evaluations=" + [string]$Snapshot.summary.venture_evaluations)
}
catch {
    Add-BusinessCertificationCheck -Name "Business Incubator Dashboard Snapshot" -Passed $false -Details $_.Exception.Message
}

try {
    $ManifestPath = "E:\AI\AI-Office\config\business-incubator\release-manifest.json"
    $Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $PassedManifest = (
        (Test-Path -LiteralPath $ManifestPath -PathType Leaf) -and
        ([string]$Manifest.version -eq "1.8.0") -and
        ([string]$Manifest.release_name -eq "Business Incubator")
    )

    Add-BusinessCertificationCheck `
        -Name "Release Manifest" `
        -Passed $PassedManifest `
        -Details ("version=" + [string]$Manifest.version)
}
catch {
    Add-BusinessCertificationCheck -Name "Release Manifest" -Passed $false -Details $_.Exception.Message
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -eq $false }).Count
$Status = if ($FailedCount -eq 0) { "certified" } else { "failed" }

$CertificationId = (
    "CERT-BIZ-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.8.0"
    release_name = "Business Incubator"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Directory = "E:\AI\AI-Office\workspace\business-incubator\certification"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null

$CertificationPath = Join-Path $Directory ($CertificationId + ".json")
$Certification | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $CertificationPath -Encoding UTF8

Write-Host ""
Write-Host "Business Incubator certification: $Status | $PassedCount passed, $FailedCount failed" `
    -ForegroundColor $(if ($Status -eq "certified") { "Green" } else { "Red" })

return [pscustomobject]$Certification

