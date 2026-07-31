param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$checks = New-Object System.Collections.Generic.List[object]

function Add-HealthCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details,
        [int]$Weight = 10
    )

    $checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
        weight = $Weight
    })
}

Add-HealthCheck `
    -Name "Automation engine" `
    -Passed (Test-Path ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1") `
    -Details "Package 13 automation engine script" `
    -Weight 15

Add-HealthCheck `
    -Name "Collaboration layer" `
    -Passed (Test-Path ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1") `
    -Details "Package 14 collaboration script" `
    -Weight 15

Add-HealthCheck `
    -Name "Executive dashboard" `
    -Passed (Test-Path ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1") `
    -Details "Package 12 executive dashboard script" `
    -Weight 15

Add-HealthCheck `
    -Name "Automation index" `
    -Passed (Test-Path ".\workspace\automation\automation-index.json") `
    -Details "Automation index data" `
    -Weight 10

Add-HealthCheck `
    -Name "Collaboration index" `
    -Passed (Test-Path ".\workspace\collaboration\collaboration-index.json") `
    -Details "Collaboration index data" `
    -Weight 10

Add-HealthCheck `
    -Name "Executive OS index" `
    -Passed (Test-Path ".\workspace\executive-os\executive-os-index.json") `
    -Details "Executive OS index data" `
    -Weight 10

Add-HealthCheck `
    -Name "Knowledge workspace" `
    -Passed (Test-Path ".\workspace\knowledge") `
    -Details "Knowledge workspace" `
    -Weight 10

Add-HealthCheck `
    -Name "Workflow workspace" `
    -Passed (Test-Path ".\workspace\workflows") `
    -Details "Workflow workspace" `
    -Weight 10

Add-HealthCheck `
    -Name "Release manifest" `
    -Passed (Test-Path ".\workspace\executive-os\release-manifest.json") `
    -Details "Version 1.0 release manifest" `
    -Weight 5

$totalWeight = 0
$passedWeight = 0

foreach ($check in $checks) {
    $checkWeight = [int]$check["weight"]
    $totalWeight += $checkWeight

    if ([bool]$check["passed"]) {
        $passedWeight += $checkWeight
    }
}

$score = 0

if ($totalWeight -gt 0) {
    $score = [int][math]::Round(($passedWeight / $totalWeight) * 100)
}

$status = "critical"

if ($score -ge 80) {
    $status = "healthy"
}
elseif ($score -ge 60) {
    $status = "warning"
}

$record = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    score = $score
    status = $status
    passed_checks = @($checks | Where-Object { $_.passed -eq $true }).Count
    failed_checks = @($checks | Where-Object { $_.passed -eq $false }).Count
    checks = @($checks | ForEach-Object { $_ })
}

$fileName = "health-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json"
$path = Join-Path ".\workspace\executive-os\health" $fileName

Write-AIOfficeExecutiveOSJson -Value $record -Path $path
Update-AIOfficeExecutiveOSIndexField -Name "office_health_score" -Value $score
Update-AIOfficeExecutiveOSIndexField -Name "office_health_status" -Value $status

Write-Host (
    "Office health: " +
    $score.ToString() +
    "% (" +
    $status +
    ")"
) -ForegroundColor Green

return [pscustomobject]$record

