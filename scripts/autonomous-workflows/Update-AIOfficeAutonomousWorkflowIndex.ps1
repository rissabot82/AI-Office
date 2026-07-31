param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$GoalFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\goals" `
        -Filter "GOAL-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$PlanFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\plans" `
        -Filter "APL-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$RunFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\runs" `
        -Filter "RUN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$Goals = @(
    foreach ($File in $GoalFiles) {
        Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName
    }
)

$Runs = @(
    foreach ($File in $RunFiles) {
        Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName
    }
)

$LatestGoal = @(
    $Goals |
        Sort-Object updated_at -Descending |
        Select-Object -First 1
)

$LatestRun = @(
    $Runs |
        Sort-Object updated_at -Descending |
        Select-Object -First 1
)

$Index = [ordered]@{
    schema_version = "1.0.0"
    version = "1.4.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    goal_count = $Goals.Count
    open_goal_count = @(
        $Goals |
            Where-Object {
                @("completed","cancelled","archived") -notcontains
                [string]$_.status
            }
    ).Count
    plan_count = $PlanFiles.Count
    active_run_count = @(
        $Runs |
            Where-Object {
                @("queued","running","waiting","waiting_approval") -contains
                [string]$_.status
            }
    ).Count
    waiting_approval_count = @(
        $Runs |
            Where-Object { [string]$_.status -eq "waiting_approval" }
    ).Count
    failed_run_count = @(
        $Runs |
            Where-Object { [string]$_.status -eq "failed" }
    ).Count
    latest_goal_id = if ($LatestGoal.Count -gt 0) {
        [string]$LatestGoal[0].goal_id
    }
    else {
        ""
    }
    latest_run_id = if ($LatestRun.Count -gt 0) {
        [string]$LatestRun[0].run_id
    }
    else {
        ""
    }
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Index `
    -Path ".\workspace\autonomous-workflows\indexes\autonomous-workflow-index.json"

Write-Host (
    "Autonomous Workflow index updated: " +
    $Goals.Count.ToString() +
    " goal(s), " +
    $Runs.Count.ToString() +
    " run(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
