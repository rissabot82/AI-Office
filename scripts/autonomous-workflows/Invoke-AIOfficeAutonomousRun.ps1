param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [int]$MaximumSteps = 25
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Run = Get-AIOfficeAutonomousRun -RunId $RunId
$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId ([string]$Run.autonomous_plan_id)
$Goal = Get-AIOfficeAutonomousGoal `
    -GoalId ([string]$Run.goal_id)

if ([string]$Run.status -eq "completed") {
    return $Run
}

$Processed = 0

foreach ($Step in @($Plan.steps | Sort-Object step_number)) {
    if ($Processed -ge $MaximumSteps) {
        break
    }

    if ([string]$Step.status -eq "completed") {
        continue
    }

    if ([string]$Step.status -eq "rejected") {
        $Run.status = "failed"
        break
    }

    if (-not (Test-AIOfficeAutonomousStepDependencies -Step $Step -Plan $Plan)) {
        continue
    }

    try {
        $Result = & ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousStep.ps1" `
            -RunId $RunId `
            -StepId ([string]$Step.step_id)

        if ([string]$Result.status -eq "waiting_approval") {
            $Run = Get-AIOfficeAutonomousRun -RunId $RunId
            break
        }

        $Processed++
        $Run = Get-AIOfficeAutonomousRun -RunId $RunId
        $Plan = Get-AIOfficeAutonomousPlan `
            -AutonomousPlanId ([string]$Run.autonomous_plan_id)
    }
    catch {
        $Plan = Get-AIOfficeAutonomousPlan `
            -AutonomousPlanId ([string]$Run.autonomous_plan_id)
        $FailedStep = @(
            $Plan.steps |
                Where-Object { [string]$_.step_id -eq [string]$Step.step_id }
        ) | Select-Object -First 1

        $FailedStep.status = "failed"

        if ($null -eq $FailedStep.PSObject.Properties["last_error"]) {
            $FailedStep | Add-Member `
                -MemberType NoteProperty `
                -Name last_error `
                -Value $_.Exception.Message
        }
        else {
            $FailedStep.last_error = $_.Exception.Message
        }

        $Plan.status = "failed"
        $Plan.updated_at = (Get-Date).ToString("o")
        Save-AIOfficeAutonomousPlan -Plan $Plan

        $Run.status = "failed"
        $Run.updated_at = (Get-Date).ToString("o")
        Save-AIOfficeAutonomousRun -Run $Run

        $Failure = [ordered]@{
            failure_id = (
                "FAIL-" +
                (Get-Date).ToString("yyyyMMdd-HHmmss") +
                "-" +
                ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
            )
            run_id = $RunId
            step_id = [string]$Step.step_id
            error = $_.Exception.Message
            created_at = (Get-Date).ToString("o")
        }

        Write-AIOfficeAutonomousWorkflowJson `
            -Value $Failure `
            -Path (
                ".\workspace\autonomous-workflows\failures\" +
                [string]$Failure.failure_id +
                ".json"
            )

        break
    }
}

$Run = Get-AIOfficeAutonomousRun -RunId $RunId
$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId ([string]$Run.autonomous_plan_id)

$Incomplete = @(
    $Plan.steps |
        Where-Object { [string]$_.status -ne "completed" }
)

if ($Incomplete.Count -eq 0) {
    $CompletedAt = (Get-Date).ToString("o")

    $Plan.status = "completed"
    $Plan.updated_at = $CompletedAt
    Save-AIOfficeAutonomousPlan -Plan $Plan

    $Run.status = "completed"
    $Run.completed_at = $CompletedAt
    $Run.updated_at = $CompletedAt
    Save-AIOfficeAutonomousRun -Run $Run

    $Goal.status = "completed"
    $Goal.updated_at = $CompletedAt

    if ($null -eq $Goal.PSObject.Properties["completed_at"]) {
        $Goal | Add-Member `
            -MemberType NoteProperty `
            -Name completed_at `
            -Value $CompletedAt
    }
    else {
        $Goal.completed_at = $CompletedAt
    }

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Goal `
        -Path ".\workspace\autonomous-workflows\goals\$($Goal.goal_id).json"
}

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

return Get-AIOfficeAutonomousRun -RunId $RunId
