param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-AutonomousCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $Checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$JsonFiles = @(
    ".\config\autonomous-workflows\autonomous-workflow-policy.json",
    ".\config\autonomous-workflows\autonomous-execution-policy.json",
    ".\config\autonomous-workflows\autonomous-worker-policy.json",
    ".\config\autonomous-workflows\release-manifest.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-AutonomousCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-AutonomousCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$Scripts = @(
    ".\scripts\autonomous-workflows\AIOfficeAutonomousWorkflows.Common.ps1",
    ".\scripts\autonomous-workflows\AIOfficeAutonomousExecution.Common.ps1",
    ".\scripts\autonomous-workflows\AIOfficeAutonomousWorker.Common.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousPlan.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousRun.ps1",
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousStep.ps1",
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1",
    ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1",
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousWorkerCycle.ps1",
    ".\scripts\autonomous-workflows\Get-AIOfficeAutonomousWorkflowMonitoring.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousWorkflowReport.ps1",
    ".\scripts\autonomous-workflows\Install-AIOfficeAutonomousWorkerTask.ps1",
    ".\scripts\autonomous-workflows\Certify-AIOfficeAutonomousWorkflows.ps1",
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflows.ps1",
    ".\scripts\autonomous-workflows\Publish-AIOfficeAutonomousWorkflowsRelease.ps1"
)

foreach ($Path in $Scripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-AutonomousCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

$GoalId = ""
$PlanId = ""
$RunId = ""

try {
    $Goal = & ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1" `
        -Title "Autonomous Workflow certification" `
        -Objective "Validate end-to-end autonomous execution and worker runtime." `
        -SuccessCriteriaJson '["Goal created","Plan created","Run completed","Worker cycle completed","Report created"]' `
        -Priority "high" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required"

    $GoalId = [string]$Goal.goal_id

    $Steps = @(
        [ordered]@{
            title = "Recall memory"
            step_type = "memory_recall"
            owner = "chief-of-staff"
        },
        [ordered]@{
            title = "Complete executive task"
            step_type = "chief_of_staff"
            owner = "chief-of-staff"
        },
        [ordered]@{
            title = "Create report"
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

    $Cycle = & ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousWorkerCycle.ps1" `
        -MaximumRuns 10 `
        -MaximumStepsPerRun 25

    $CompletedRun = Get-AIOfficeAutonomousRun -RunId $RunId

    Add-AutonomousCheck `
        -Name "Worker-cycle execution" `
        -Passed ([string]$CompletedRun.status -eq "completed") `
        -Details (
            [string]$Cycle.worker_cycle_id +
            " | run " +
            $RunId
        )

    $Monitoring = & `
        ".\scripts\autonomous-workflows\Get-AIOfficeAutonomousWorkflowMonitoring.ps1"

    Add-AutonomousCheck `
        -Name "Workflow monitoring" `
        -Passed ($null -ne $Monitoring) `
        -Details ([string]$Monitoring.monitoring_id)

    $Report = & `
        ".\scripts\autonomous-workflows\New-AIOfficeAutonomousWorkflowReport.ps1"

    Add-AutonomousCheck `
        -Name "Executive workflow report" `
        -Passed ($null -ne $Report) `
        -Details ([string]$Report.report_id)
}
catch {
    Add-AutonomousCheck `
        -Name "Offline end-to-end Autonomous Workflow runtime" `
        -Passed $false `
        -Details $_.Exception.Message
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
                $Record = Read-AIOfficeAutonomousWorkflowJson -Path $_.FullName

                if ($null -ne $Record -and
                    [string]$Record.run_id -eq $RunId) {
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

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

$PassedCount = @(
    $Checks | Where-Object { $_.passed -eq $true }
).Count

$FailedCount = @(
    $Checks | Where-Object { $_.passed -eq $false }
).Count

$Status = if ($FailedCount -eq 0) {
    "certified"
}
else {
    "failed"
}

$CertificationId = (
    "CERT-AWF-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.4.0"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Certification `
    -Path (
        ".\workspace\autonomous-workflows\certification\" +
        $CertificationId +
        ".json"
    )

Write-Host (
    "Autonomous Workflows certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
