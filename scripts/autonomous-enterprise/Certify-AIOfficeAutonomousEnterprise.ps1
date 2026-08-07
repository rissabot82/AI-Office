param()

$ErrorActionPreference = "Stop"

$Checks = New-Object System.Collections.Generic.List[object]

function Add-CertificationCheck {
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

$PartA = & powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File "E:\AI\AI-Office\scripts\autonomous-enterprise\Test-AIOfficeEnterpriseArchitecture.ps1" 2>&1

$PartAExit = $LASTEXITCODE
$PartAText = ($PartA | Out-String).Trim()

$PartAPassed = (
    $PartAExit -eq 0 -and
    $PartAText -like "*All AI Office v2.0 Part A Autonomous AI Enterprise Architecture checks passed.*"
)

Add-CertificationCheck `
    -Name "Part A Autonomous AI Enterprise Architecture" `
    -Passed $PartAPassed `
    -Details $(if ($PartAPassed) { "Validation passed." } else { $PartAText })

$PartB = & powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File "E:\AI\AI-Office\scripts\autonomous-enterprise\Test-AIOfficeEnterpriseOrchestrationRuntime.ps1" 2>&1

$PartBExit = $LASTEXITCODE
$PartBText = ($PartB | Out-String).Trim()

$PartBPassed = (
    $PartBExit -eq 0 -and
    $PartBText -like "*All AI Office v2.0 Part B Enterprise Orchestration Runtime checks passed.*"
)

Add-CertificationCheck `
    -Name "Part B Enterprise Orchestration Runtime" `
    -Passed $PartBPassed `
    -Details $(if ($PartBPassed) { "Validation passed." } else { $PartBText })

try {
    $Snapshot = & "E:\AI\AI-Office\scripts\autonomous-enterprise\Test-AIOfficeEnterpriseDashboard.ps1" 2>&1
    Add-CertificationCheck -Name "Enterprise Dashboard" -Passed $true -Details "Dashboard validation passed."
}
catch {
    Add-CertificationCheck -Name "Enterprise Dashboard" -Passed $false -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\autonomous-enterprise\release-manifest.json" `
        -Raw |
        ConvertFrom-Json

    $ManifestPassed = ([string]$Manifest.version -eq "2.0.0")
    Add-CertificationCheck `
        -Name "Release Manifest" `
        -Passed $ManifestPassed `
        -Details ("version=" + [string]$Manifest.version)
}
catch {
    Add-CertificationCheck -Name "Release Manifest" -Passed $false -Details $_.Exception.Message
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -ne $true }).Count
$Status = if ($FailedCount -eq 0) { "certified" } else { "failed" }

$Certification = [pscustomobject]@{
    certification_id = "CERT-ENT-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
    version = "2.0.0"
    release_name = "Autonomous AI Enterprise"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$CertificationDirectory = "E:\AI\AI-Office\workspace\autonomous-enterprise\certifications"
New-Item -ItemType Directory -Path $CertificationDirectory -Force | Out-Null

$Certification |
    ConvertTo-Json -Depth 50 |
    Set-Content `
        -LiteralPath (Join-Path $CertificationDirectory ($Certification.certification_id + ".json")) `
        -Encoding UTF8

Write-Host ""
Write-Host "Autonomous AI Enterprise certification: $Status | $PassedCount passed, $FailedCount failed" `
    -ForegroundColor $(if ($Status -eq "certified") { "Green" } else { "Red" })

return $Certification

