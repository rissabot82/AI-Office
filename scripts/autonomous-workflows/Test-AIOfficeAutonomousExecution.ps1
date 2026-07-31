param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.4 Part B Autonomous Execution and Recovery..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\autonomous-workflows\autonomous-execution-policy.json",
    ".\config\autonomous-workflows\step-result-schema.json",
    ".\config\autonomous-workflows\approval-schema.json",
    ".\config\autonomous-workflows\recovery-schema.json",
    ".\workspace\templates\autonomous-step-result-template.json"
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
    ".\scripts\autonomous-workflows\AIOfficeAutonomousExecution.Common.ps1",
    ".\scripts\autonomous-workflows\Set-AIOfficeAutonomousApproval.ps1",
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousStep.ps1",
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1",
    ".\scripts\autonomous-workflows\Retry-AIOfficeAutonomousStep.ps1",
    ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1",
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousExecution.ps1"
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
$MessageIds = New-Object System.Collections.Generic.List[string]

try {
    $Goal = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1" `
        -Title "Autonomous execution validation" `
        -Objective "Validate memory recall, department dispatch, approval, report, checkpoints, and recovery." `
        -SuccessCriteriaJson '["Memory recalled","Department dispatched","Approval granted","Report completed"]' `
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
            title = "Dispatch marketing work"
            step_type = "department"
            owner = "marketing"
            department = "marketing"
        },
        [ordered]@{
            title = "Human review"
            step_type = "human_approval"
            owner = "chief-of-staff"
        },
        [ordered]@{
            title = "Create completion report"
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

    $Run = & ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1" `
        -RunId $RunId `
        -MaximumSteps 10

    if ([string]$Run.status -ne "waiting_approval") {
        throw "Workflow did not pause for human approval."
    }

    $Plan = Get-Content `
        ".\workspace\autonomous-workflows\plans\$PlanId.json" `
        -Raw |
        ConvertFrom-Json

    $ApprovalStep = @(
        $Plan.steps |
            Where-Object { [string]$_.step_type -eq "human_approval" }
    ) | Select-Object -First 1

    & ".\scripts\autonomous-workflows\Set-AIOfficeAutonomousApproval.ps1" `
        -RunId $RunId `
        -StepId ([string]$ApprovalStep.step_id) `
        -Status "approved" `
        -Decision "Validation approval granted." |
        Out-Null

    $Run = & ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1" `
        -RunId $RunId `
        -MaximumSteps 10

    if ([string]$Run.status -ne "completed") {
        throw "Autonomous workflow did not complete after approval."
    }

    Write-Host "[EXECUTION OK] $RunId" -ForegroundColor Green
}
catch {
    Write-Host "[EXECUTION ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Autonomous execution failed: " + $_.Exception.Message)
}

try {
    $RunPath = ".\workspace\autonomous-workflows\runs\$RunId.json"
    $Run = Get-Content -LiteralPath $RunPath -Raw | ConvertFrom-Json
    $Run.status = "running"
    $Run.updated_at = (Get-Date).ToString("o")
    $Run |
        ConvertTo-Json -Depth 80 |
        Set-Content -LiteralPath $RunPath -Encoding UTF8

    $Recovered = @(
        & ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1" `
            -RunId $RunId
    )

    if ($Recovered.Count -ne 1 -or
        [string]$Recovered[0].recovered_status -ne "running") {
        throw "Autonomous workflow recovery did not recover the validation run."
    }

    Write-Host "[RECOVERY OK] $RunId" -ForegroundColor Green
}
catch {
    Write-Host "[RECOVERY ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Autonomous recovery failed: " + $_.Exception.Message)
}

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\messages" `
        -Recurse `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    try {
        $Message = Get-Content -LiteralPath $File.FullName -Raw |
            ConvertFrom-Json

        if (
            $null -ne $Message.payload -and
            (
                [string]$Message.payload.autonomous_run_id -eq $RunId -or
                [string]$Message.payload.autonomous_step_id -like "STEP-*"
            )
        ) {
            $MessageIds.Add([string]$Message.message_id)
            Remove-Item -LiteralPath $File.FullName -Force
        }
    }
    catch {
    }
}

foreach ($Path in @(
    ".\workspace\autonomous-workflows\goals\$GoalId.json",
    ".\workspace\autonomous-workflows\plans\$PlanId.json",
    ".\workspace\autonomous-workflows\runs\$RunId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Folder in @(
    "checkpoints",
    "step-results",
    "approvals",
    "retries",
    "recovery",
    "failures"
)) {
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\$Folder" `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                $Record = Get-Content -LiteralPath $_.FullName -Raw |
                    ConvertFrom-Json

                if ([string]$Record.run_id -eq $RunId) {
                    Remove-Item -LiteralPath $_.FullName -Force
                }
            }
            catch {
            }
        }
}

Get-ChildItem `
    -LiteralPath ".\workspace\memory\context-packets" `
    -Filter "CTXMEM-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        try {
            $Packet = Get-Content -LiteralPath $_.FullName -Raw |
                ConvertFrom-Json

            if ([string]$Packet.requested_by -eq "autonomous-workflow-engine") {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
        catch {
        }
    }

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Autonomous Execution and Recovery error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.4 Part B Autonomous Execution and Recovery checks passed." `
    -ForegroundColor Green
