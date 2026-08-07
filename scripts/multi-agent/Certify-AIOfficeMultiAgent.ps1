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

function Invoke-ValidationScript {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [Parameter(Mandatory=$true)][string]$CheckName
    )

    $Output = & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $ScriptPath 2>&1

    $ExitCode = $LASTEXITCODE
    $Text = ($Output | Out-String).Trim()

    if ($ExitCode -eq 0) {
        Add-CertificationCheck `
            -Name $CheckName `
            -Passed $true `
            -Details "Validation passed."

        return $true
    }

    Add-CertificationCheck `
        -Name $CheckName `
        -Passed $false `
        -Details $Text

    return $false
}

$CertificationId = "CERT-MA-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"

Invoke-ValidationScript `
    -ScriptPath "E:\AI\AI-Office\scripts\multi-agent\Test-AIOfficeMultiAgentArchitecture.ps1" `
    -CheckName "Part A Multi-Agent Architecture" |
    Out-Null

Invoke-ValidationScript `
    -ScriptPath "E:\AI\AI-Office\scripts\multi-agent\Test-AIOfficeCollaborationRuntime.ps1" `
    -CheckName "Part B Collaboration Runtime" |
    Out-Null

try {
    $Snapshot = & "E:\AI\AI-Office\scripts\multi-agent\New-AIOfficeMultiAgentDashboardSnapshot.ps1"

    $SnapshotPath = "E:\AI\AI-Office\dashboard\public\multi-agent-status.json"
    $SnapshotExists = Test-Path -LiteralPath $SnapshotPath -PathType Leaf
    $SnapshotPresent = ($null -ne $Snapshot)
    $Passed = ($SnapshotPresent -and $SnapshotExists)

    Add-CertificationCheck `
        -Name "Multi-Agent Dashboard Snapshot" `
        -Passed $Passed `
        -Details (
            "agents=" + [string]$Snapshot.agent_count +
            "; assignments=" + [string]$Snapshot.assignment_count +
            "; collaborations=" + [string]$Snapshot.collaboration_count
        )
}
catch {
    Add-CertificationCheck `
        -Name "Multi-Agent Dashboard Snapshot" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\multi-agent\release-manifest.json" `
        -Raw |
        ConvertFrom-Json

    Add-CertificationCheck `
        -Name "Release Manifest" `
        -Passed ([string]$Manifest.version -eq "1.6.0") `
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
    version = "1.6.0"
    release_name = "Multi-Agent Collaboration"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedChecks
    failed_checks = $FailedChecks
    checks = @($Checks | ForEach-Object { $_ })
}

$CertificationDirectory = "E:\AI\AI-Office\workspace\multi-agent\certification"

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
    "Multi-Agent certification: " +
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
