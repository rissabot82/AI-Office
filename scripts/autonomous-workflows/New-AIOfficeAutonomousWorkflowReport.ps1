param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Index = & ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1"
$Monitoring = & ".\scripts\autonomous-workflows\Get-AIOfficeAutonomousWorkflowMonitoring.ps1"

$Goals = @(
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath ".\workspace\autonomous-workflows\goals" `
            -Filter "GOAL-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName
    }
)

$Runs = @(
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath ".\workspace\autonomous-workflows\runs" `
            -Filter "RUN-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName
    }
)

$CheckpointCount = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\checkpoints" `
        -Filter "CHK-*.json" `
        -File `
        -ErrorAction SilentlyContinue
).Count

$ApprovalCount = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\approvals" `
        -Filter "APRWF-*.json" `
        -File `
        -ErrorAction SilentlyContinue
).Count

$FailureCount = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\failures" `
        -Filter "FAIL-*.json" `
        -File `
        -ErrorAction SilentlyContinue
).Count

$ReportId = (
    "AWR-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Report = [ordered]@{
    report_id = $ReportId
    generated_at = (Get-Date).ToString("o")
    status = [string]$Monitoring.status
    goal_count = [int]$Index.goal_count
    open_goal_count = [int]$Index.open_goal_count
    plan_count = [int]$Index.plan_count
    active_run_count = [int]$Index.active_run_count
    waiting_approval_count = [int]$Index.waiting_approval_count
    failed_run_count = [int]$Index.failed_run_count
    checkpoint_count = $CheckpointCount
    approval_record_count = $ApprovalCount
    failure_record_count = $FailureCount
    warning_count = [int]$Monitoring.warning_count
    warnings = @($Monitoring.warnings)
    goals = $Goals
    runs = $Runs
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Report `
    -Path ".\workspace\autonomous-workflows\reports\$ReportId.json"

Write-Host "Autonomous workflow executive report created: $ReportId" `
    -ForegroundColor Green

return [pscustomobject]$Report
