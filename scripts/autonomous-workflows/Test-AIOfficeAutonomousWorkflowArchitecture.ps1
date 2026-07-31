param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.4 Part A Autonomous Workflow Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\autonomous-workflows\autonomous-workflow-policy.json",
    ".\config\autonomous-workflows\goal-schema.json",
    ".\config\autonomous-workflows\plan-schema.json",
    ".\config\autonomous-workflows\run-schema.json",
    ".\config\autonomous-workflows\checkpoint-schema.json",
    ".\workspace\templates\autonomous-goal-template.json",
    ".\workspace\templates\autonomous-plan-template.json",
    ".\workspace\templates\autonomous-run-template.json",
    ".\workspace\autonomous-workflows\indexes\autonomous-workflow-index.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\autonomous-workflows\AIOfficeAutonomousWorkflows.Common.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousPlan.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousRun.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1",
    ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1",
    ".\scripts\autonomous-workflows\Show-AIOfficeAutonomousWorkflowStatus.ps1",
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflowArchitecture.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

$GoalId = ""
$PlanId = ""
$RunId = ""
$CheckpointId = ""

try {
    $Goal = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1" `
        -Title "Autonomous workflow validation" `
        -Objective "Validate goal, plan, run, and checkpoint persistence." `
        -SuccessCriteriaJson '["Goal created","Plan created","Run created","Checkpoint created"]' `
        -Priority "high" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required"

    $GoalId = [string]$Goal.goal_id

    $Steps = @(
        [ordered]@{
            title = "Recall relevant memory"
            step_type = "memory_recall"
            owner = "chief-of-staff"
        },
        [ordered]@{
            title = "Execute marketing work"
            step_type = "department"
            owner = "marketing"
            department = "marketing"
        },
        [ordered]@{
            title = "Generate final report"
            step_type = "report"
            owner = "chief-of-staff"
        }
    )

    $Plan = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousPlan.ps1" `
        -GoalId $GoalId `
        -StepsJson ($Steps | ConvertTo-Json -Depth 20 -Compress)

    $PlanId = [string]$Plan.autonomous_plan_id

    $Run = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousRun.ps1" `
        -AutonomousPlanId $PlanId

    $RunId = [string]$Run.run_id

    $Checkpoint = & `
        ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1" `
        -RunId $RunId `
        -StepId ([string]$Plan.steps[0].step_id) `
        -Stage "before" `
        -StateJson '{"status":"ready","current_step":1}'

    $CheckpointId = [string]$Checkpoint.checkpoint_id

    if (
        [string]::IsNullOrWhiteSpace($GoalId) -or
        [string]::IsNullOrWhiteSpace($PlanId) -or
        [string]::IsNullOrWhiteSpace($RunId) -or
        [string]::IsNullOrWhiteSpace($CheckpointId)
    ) {
        throw "One or more autonomous workflow IDs were not created."
    }

    Write-Host (
        "[WORKFLOW OK] " +
        $GoalId +
        " | " +
        $PlanId +
        " | " +
        $RunId
    ) -ForegroundColor Green
}
catch {
    Write-Host "[WORKFLOW ER] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Autonomous workflow creation failed: " + $_.Exception.Message)
}

try {
    $Index = & `
        ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1"

    if (
        $null -eq $Index -or
        [int]$Index.goal_count -lt 1 -or
        [int]$Index.plan_count -lt 1 -or
        [int]$Index.active_run_count -lt 1
    ) {
        throw "Autonomous Workflow index did not contain validation records."
    }

    Write-Host "[INDEX OK   ] Workflow index validation passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Autonomous Workflow index failed: " + $_.Exception.Message)
}

foreach ($Path in @(
    ".\workspace\autonomous-workflows\goals\$GoalId.json",
    ".\workspace\autonomous-workflows\plans\$PlanId.json",
    ".\workspace\autonomous-workflows\runs\$RunId.json",
    ".\workspace\autonomous-workflows\checkpoints\$CheckpointId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Autonomous Workflow architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.4 Part A Autonomous Workflow Architecture checks passed." `
    -ForegroundColor Green
