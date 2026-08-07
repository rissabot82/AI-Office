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

function Invoke-FinancialValidation {
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
        return
    }

    Add-CertificationCheck `
        -Name $CheckName `
        -Passed $false `
        -Details $Text
}

$CertificationId = "CERT-FIN-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"

Invoke-FinancialValidation `
    -ScriptPath "E:\AI\AI-Office\scripts\financial-office\Test-AIOfficeFinancialOfficeArchitecture.ps1" `
    -CheckName "Part A Financial Office Architecture"

Invoke-FinancialValidation `
    -ScriptPath "E:\AI\AI-Office\scripts\financial-office\Test-AIOfficeFinancialPlanning.ps1" `
    -CheckName "Part B Planning and Analysis"

try {
    $Snapshot = & "E:\AI\AI-Office\scripts\financial-office\New-AIOfficeFinancialDashboardSnapshot.ps1"

    $SnapshotPath = "E:\AI\AI-Office\dashboard\public\financial-office-status.json"
    $SnapshotExists = Test-Path -LiteralPath $SnapshotPath -PathType Leaf
    $SnapshotPresent = ($null -ne $Snapshot)

    Add-CertificationCheck `
        -Name "Financial Office Dashboard Snapshot" `
        -Passed ($SnapshotPresent -and $SnapshotExists) `
        -Details (
            "accounts=" + [string]$Snapshot.account_count +
            "; debts=" + [string]$Snapshot.debt_count +
            "; goals=" + [string]$Snapshot.goal_count
        )
}
catch {
    Add-CertificationCheck `
        -Name "Financial Office Dashboard Snapshot" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\financial-office\release-manifest.json" `
        -Raw |
        ConvertFrom-Json

    Add-CertificationCheck `
        -Name "Release Manifest" `
        -Passed ([string]$Manifest.version -eq "1.7.0") `
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
    version = "1.7.0"
    release_name = "Personal Financial Office"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedChecks
    failed_checks = $FailedChecks
    checks = @($Checks | ForEach-Object { $_ })
}

$CertificationDirectory = "E:\AI\AI-Office\workspace\financial-office\certification"

if (-not (Test-Path -LiteralPath $CertificationDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $CertificationDirectory -Force | Out-Null
}

$Record |
    ConvertTo-Json -Depth 80 |
    Set-Content `
        -LiteralPath (Join-Path $CertificationDirectory ($CertificationId + ".json")) `
        -Encoding UTF8

Write-Host ""
Write-Host (
    "Financial Office certification: " +
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
