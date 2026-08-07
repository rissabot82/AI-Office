param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Checks = New-Object System.Collections.Generic.List[object]

function Add-CertificationCheck {
    param([string]$Name,[bool]$Passed,[string]$Details="")
    $Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

function Invoke-Validation {
    param([string]$Name,[string]$ScriptPath)
    try {
        $Output = & powershell -NoProfile -ExecutionPolicy Bypass -File $ScriptPath 2>&1
        $Passed = ($LASTEXITCODE -eq 0)
        Add-CertificationCheck -Name $Name -Passed $Passed -Details $(if ($Passed) { "Validation passed." } else { ($Output | Out-String).Trim() })
    }
    catch {
        Add-CertificationCheck -Name $Name -Passed $false -Details $_.Exception.Message
    }
}

Invoke-Validation `
    -Name "Part A Operations and Integrations Architecture" `
    -ScriptPath "E:\AI\AI-Office\scripts\operations-integrations\Test-AIOfficeOperationsArchitecture.ps1"

Invoke-Validation `
    -Name "Part B Operational Runtime and External Intake" `
    -ScriptPath "E:\AI\AI-Office\scripts\operations-integrations\Test-AIOfficeOperationalRuntime.ps1"

try {
    $Snapshot = & "E:\AI\AI-Office\scripts\operations-integrations\New-AIOfficeOperationsDashboardSnapshot.ps1"
    $SnapshotOk = (
        $null -ne $Snapshot -and
        $null -ne $Snapshot.metrics -and
        (Test-Path -LiteralPath "E:\AI\AI-Office\dashboard\data\operations-integrations.json" -PathType Leaf)
    )
    Add-CertificationCheck `
        -Name "Operations Dashboard Snapshot" `
        -Passed $SnapshotOk `
        -Details ("integrations=" + [string]$Snapshot.metrics.integrations + "; jobs=" + [string]$Snapshot.metrics.jobs)
}
catch {
    Add-CertificationCheck -Name "Operations Dashboard Snapshot" -Passed $false -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\operations-integrations\release-manifest.json" `
        -Raw |
        ConvertFrom-Json

    $ManifestOk = (
        [string]$Manifest.version -eq "1.9.0" -and
        [string]$Manifest.release_name -eq "Operations and Integrations"
    )

    Add-CertificationCheck `
        -Name "Release Manifest" `
        -Passed $ManifestOk `
        -Details ("version=" + [string]$Manifest.version)
}
catch {
    Add-CertificationCheck -Name "Release Manifest" -Passed $false -Details $_.Exception.Message
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -eq $false }).Count
$Status = if ($FailedCount -eq 0) { "certified" } else { "failed" }

$Certification = [ordered]@{
    certification_id = (
        "CERT-OPS-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    version = "1.9.0"
    release_name = "Operations and Integrations"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Directory = "E:\AI\AI-Office\workspace\operations-integrations\certification"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null
$Path = Join-Path $Directory ($Certification.certification_id + ".json")
$Certification | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $Path -Encoding UTF8

Write-Host ""
Write-Host ("Operations and Integrations certification: " + $Status + " | " + $PassedCount + " passed, " + $FailedCount + " failed") `
    -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification

