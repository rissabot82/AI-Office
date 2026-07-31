param(
    [switch]$SkipAutomation,
    [switch]$SkipDashboard
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$started = Get-Date
$steps = New-Object System.Collections.Generic.List[object]

function Add-StartupStep {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details
    )

    $steps.Add([ordered]@{
        name = $Name
        status = $Status
        details = $Details
    })
}

try {
    if (-not $SkipAutomation -and
        (Test-Path ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1")) {
        & ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1" | Out-Null
        Add-StartupStep "Automation engine" "success" "Queue processed."
    }
    else {
        Add-StartupStep "Automation engine" "skipped" "Not available or skipped."
    }
}
catch {
    Add-StartupStep "Automation engine" "warning" $_.Exception.Message
}

try {
    if (Test-Path ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1") {
        & ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null
        Add-StartupStep "Collaboration index" "success" "Index refreshed."
    }
    else {
        Add-StartupStep "Collaboration index" "skipped" "Script not found."
    }
}
catch {
    Add-StartupStep "Collaboration index" "warning" $_.Exception.Message
}

try {
    if (-not $SkipDashboard -and
        (Test-Path ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1")) {
        & ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" | Out-Null
        Add-StartupStep "Executive dashboard" "success" "Snapshot generated."
    }
    else {
        Add-StartupStep "Executive dashboard" "skipped" "Not available or skipped."
    }
}
catch {
    Add-StartupStep "Executive dashboard" "warning" $_.Exception.Message
}

try {
    $health = & ".\scripts\executive-os\Get-AIOfficeHealthReport.ps1"
    Add-StartupStep `
        "Office health" `
        "success" `
        ($health.score.ToString() + "% " + [string]$health.status)
}
catch {
    Add-StartupStep "Office health" "warning" $_.Exception.Message
}

try {
    $briefing = & ".\scripts\executive-os\New-AIOfficeExecutiveBriefing.ps1" `
        -Type "daily"
    Add-StartupStep `
        "Daily briefing" `
        "success" `
        ([string]$briefing.briefing_id)
}
catch {
    Add-StartupStep "Daily briefing" "warning" $_.Exception.Message
}

$completed = Get-Date
$record = [ordered]@{
    startup_id = "START-" + $started.ToString("yyyyMMdd-HHmmss")
    started_at = $started.ToString("o")
    completed_at = $completed.ToString("o")
    duration_seconds = [math]::Round(($completed - $started).TotalSeconds, 2)
    steps = @($steps | ForEach-Object { $_ })
}

$path = Join-Path `
    ".\workspace\executive-os\logs" `
    ("startup-" + $started.ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeExecutiveOSJson -Value $record -Path $path
Update-AIOfficeExecutiveOSIndexField `
    -Name "last_startup_at" `
    -Value $record.completed_at

Write-Host ""
Write-Host "AI Office startup routine completed." -ForegroundColor Green
Write-Host ""

return [pscustomobject]$record
