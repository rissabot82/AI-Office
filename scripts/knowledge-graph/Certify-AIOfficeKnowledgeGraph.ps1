param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

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

$CertificationId = (
    "CERT-KG-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

try {
    & "E:\AI\AI-Office\scripts\knowledge-graph\Test-AIOfficeKnowledgeGraphArchitecture.ps1"

    Add-CertificationCheck `
        -Name "Part A Knowledge Graph Architecture" `
        -Passed $true `
        -Details "Architecture validation passed."
}
catch {
    Add-CertificationCheck `
        -Name "Part A Knowledge Graph Architecture" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    & "E:\AI\AI-Office\scripts\knowledge-graph\Test-AIOfficeKnowledgeReasoning.ps1"

    Add-CertificationCheck `
        -Name "Part B Extraction and Reasoning" `
        -Passed $true `
        -Details "Reasoning validation passed."
}
catch {
    Add-CertificationCheck `
        -Name "Part B Extraction and Reasoning" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    $Snapshot = & "E:\AI\AI-Office\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphDashboardSnapshot.ps1"

    $Passed = (
        ($null -ne $Snapshot) -and
        (
            Test-Path `
                -LiteralPath "E:\AI\AI-Office\dashboard\public\knowledge-graph-status.json" `
                -PathType Leaf
        )
    )

    Add-CertificationCheck `
        -Name "Knowledge Graph Dashboard Snapshot" `
        -Passed $Passed `
        -Details (
            "entities=" + [string]$Snapshot.entity_count +
            "; relationships=" + [string]$Snapshot.relationship_count
        )
}
catch {
    Add-CertificationCheck `
        -Name "Knowledge Graph Dashboard Snapshot" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\knowledge-graph\release-manifest.json" `
        -Raw |
        ConvertFrom-Json

    Add-CertificationCheck `
        -Name "Release Manifest" `
        -Passed ([string]$Manifest.version -eq "1.5.0") `
        -Details ("version=" + [string]$Manifest.version)
}
catch {
    Add-CertificationCheck `
        -Name "Release Manifest" `
        -Passed $false `
        -Details $_.Exception.Message
}

$PassedChecks = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedChecks = @($Checks | Where-Object { $_.passed -eq $false }).Count
$Status = if ($FailedChecks -eq 0) { "certified" } else { "failed" }

$Record = [ordered]@{
    certification_id = $CertificationId
    version = "1.5.0"
    release_name = "Knowledge Graph and Reasoning"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedChecks
    failed_checks = $FailedChecks
    checks = @($Checks | ForEach-Object { $_ })
}

$CertificationDirectory = "E:\AI\AI-Office\workspace\knowledge-graph\certification"

if (-not (Test-Path -LiteralPath $CertificationDirectory -PathType Container)) {
    New-Item `
        -ItemType Directory `
        -Path $CertificationDirectory `
        -Force |
        Out-Null
}

$Record |
    ConvertTo-Json -Depth 80 |
    Set-Content `
        -LiteralPath (Join-Path $CertificationDirectory ($CertificationId + ".json")) `
        -Encoding UTF8

Write-Host ""
Write-Host (
    "Knowledge Graph certification: " +
    $Status +
    " | " +
    $PassedChecks +
    " passed, " +
    $FailedChecks +
    " failed"
) -ForegroundColor $(if ($FailedChecks -eq 0) { "Green" } else { "Red" })

if ($FailedChecks -gt 0) {
    exit 1
}

return [pscustomobject]$Record


