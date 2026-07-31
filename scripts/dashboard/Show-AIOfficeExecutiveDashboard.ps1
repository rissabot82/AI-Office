param(
    [string]$SnapshotId = "",
    [switch]$CreateNew
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

if ($CreateNew) {
    & ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" |
        Out-Null
}

& ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" |
    Out-Null

$index = Read-AIOfficeJsonFile `
    -Path ".\workspace\dashboard\dashboard-index.json"

if ($null -eq $index -or [int]$index.snapshot_count -eq 0) {
    throw "No dashboard snapshots are available. Run New-AIOfficeExecutiveSnapshot.ps1 first."
}

$snapshotFile = ""

if ([string]::IsNullOrWhiteSpace($SnapshotId)) {
    $snapshotFile = [string]$index.latest_snapshot
}
else {
    $match = @(
        $index.snapshots |
        Where-Object {
            $_.snapshot_id -eq $SnapshotId -or
            $_.file -eq $SnapshotId
        }
    ) | Select-Object -First 1

    if ($null -eq $match) {
        throw "Dashboard snapshot not found: $SnapshotId"
    }

    $snapshotFile = [string]$match.file
}

$snapshotPath = Join-Path `
    ".\workspace\dashboard\snapshots" `
    $snapshotFile

$snapshot = Read-AIOfficeJsonFile -Path $snapshotPath

if ($null -eq $snapshot) {
    throw "Dashboard snapshot could not be loaded: $snapshotPath"
}

Write-Host ""
Write-Host "AI OFFICE EXECUTIVE DASHBOARD" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Generated: " + [string]$snapshot.generated_at)
Write-Host (
    "Health: " +
    [string]$snapshot.overall_health.status.ToUpperInvariant() +
    " (" +
    [string]$snapshot.overall_health.score +
    "/100)"
)
Write-Host ""

Write-Host "EXECUTIVE SUMMARY" -ForegroundColor Yellow
Write-Host ([string]$snapshot.executive_summary)
Write-Host ""

Write-Host "KEY METRICS" -ForegroundColor Yellow
Write-Host (
    "Workflows : " +
    [string]$snapshot.metrics.workflows.total +
    " total | " +
    [string]$snapshot.metrics.workflows.active +
    " active | " +
    [string]$snapshot.metrics.workflows.blocked +
    " blocked | " +
    [string]$snapshot.metrics.workflows.overdue +
    " overdue"
)

Write-Host (
    "Approvals : " +
    [string]$snapshot.metrics.approvals.total +
    " total | " +
    [string]$snapshot.metrics.approvals.pending +
    " pending | " +
    [string]$snapshot.metrics.approvals.approved +
    " approved"
)

Write-Host (
    "Calendar  : " +
    [string]$snapshot.metrics.calendar.total +
    " total | " +
    [string]$snapshot.metrics.calendar.today +
    " today | " +
    [string]$snapshot.metrics.calendar.next_7_days +
    " next 7 days | " +
    [string]$snapshot.metrics.calendar.overdue +
    " overdue"
)

Write-Host (
    "Knowledge : " +
    [string]$snapshot.metrics.knowledge.total +
    " total | " +
    [string]$snapshot.metrics.knowledge.active +
    " active | " +
    [string]$snapshot.metrics.knowledge.stale +
    " stale"
)

Write-Host (
    "System    : " +
    [string]$snapshot.metrics.system.json_files_checked +
    " JSON checked | " +
    [string]$snapshot.metrics.system.invalid_json_files +
    " invalid | " +
    [string]$snapshot.metrics.system.required_components_missing +
    " components missing"
)

Write-Host ""
Write-Host "RISKS" -ForegroundColor Yellow

if (@($snapshot.risks).Count -eq 0) {
    Write-Host "No material risks detected."
}
else {
    foreach ($risk in @($snapshot.risks)) {
        Write-Host (
            "[" +
            [string]$risk.severity.ToUpperInvariant() +
            "] " +
            [string]$risk.title
        )

        Write-Host ("  " + [string]$risk.detail)
        Write-Host (
            "  Action: " +
            [string]$risk.recommended_action
        )
    }
}

Write-Host ""
Write-Host "RECOMMENDATIONS" -ForegroundColor Yellow

if (@($snapshot.recommendations).Count -eq 0) {
    Write-Host "No immediate corrective actions are required."
}
else {
    foreach ($recommendation in @($snapshot.recommendations)) {
        Write-Host ("- " + [string]$recommendation)
    }
}

Write-Host ""
return $snapshot
