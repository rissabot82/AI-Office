# ============================================================
# AI Office v1.4 - Part C
# Worker Runtime, Monitoring, Certification, and Release
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.4 Parts A and B
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\autonomous-workflows\autonomous-workflow-policy.json",
    ".\config\autonomous-workflows\autonomous-execution-policy.json",
    ".\scripts\autonomous-workflows\AIOfficeAutonomousWorkflows.Common.ps1",
    ".\scripts\autonomous-workflows\AIOfficeAutonomousExecution.Common.ps1",
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1",
    ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1",
    ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.4 Parts A and B are required. Missing: $RequiredPath"
    }
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function Write-NewFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $Parent = Split-Path -Parent $Path

        if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
            New-Item -ItemType Directory -Path $Parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

@(
    ".\workspace\autonomous-workflows\monitoring",
    ".\workspace\autonomous-workflows\reports",
    ".\workspace\autonomous-workflows\certification",
    ".\workspace\autonomous-workflows\releases",
    ".\workspace\autonomous-workflows\workers\history"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$WorkerPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.4.0",
  "part": "C",
  "worker": {
    "enabled": true,
    "default_maximum_runs_per_cycle": 10,
    "default_maximum_steps_per_run": 25,
    "recover_before_processing": true,
    "continue_after_run_failure": true,
    "persist_cycle_history": true
  },
  "monitoring": {
    "enabled": true,
    "stale_run_after_hours": 24,
    "warning_run_after_hours": 8,
    "include_waiting_approvals": true,
    "include_failures": true,
    "include_retry_exhaustion": true
  },
  "reporting": {
    "executive_summary": true,
    "include_goals": true,
    "include_runs": true,
    "include_failures": true,
    "include_approvals": true,
    "include_checkpoint_counts": true
  },
  "scheduling": {
    "task_name": "AI Office Autonomous Workflow Worker",
    "default_interval_minutes": 15,
    "start_when_available": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\autonomous-workflows\autonomous-worker-policy.json" $WorkerPolicy

$WorkerCycleSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-worker-cycle-schema.json",
  "title": "AI Office Autonomous Worker Cycle",
  "type": "object",
  "required": [
    "worker_cycle_id",
    "started_at",
    "completed_at",
    "status",
    "recovered_run_count",
    "processed_run_count",
    "completed_run_count",
    "failed_run_count"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\worker-cycle-schema.json" $WorkerCycleSchema

$MonitoringSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-monitoring-schema.json",
  "title": "AI Office Autonomous Monitoring Report",
  "type": "object",
  "required": [
    "monitoring_id",
    "generated_at",
    "status",
    "active_run_count",
    "waiting_approval_count",
    "failed_run_count",
    "warning_count"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\monitoring-schema.json" $MonitoringSchema

$ReleaseManifest = @"
{
  "product": "AI Office",
  "component": "Autonomous Workflows",
  "version": "1.4.0",
  "release_name": "Autonomous Workflows",
  "release_status": "installed",
  "installed_at": "$Now",
  "parts": {
    "A": "Autonomous Workflow Architecture",
    "B": "Autonomous Execution and Recovery",
    "C": "Worker Runtime, Monitoring, Certification, and Release"
  },
  "capabilities": [
    "executive_goals",
    "persistent_plans",
    "workflow_runs",
    "step_dependencies",
    "human_approval_gates",
    "memory_recall",
    "department_dispatch",
    "message_bus_dispatch",
    "openclaw_dispatch",
    "checkpoints",
    "retries",
    "recovery",
    "background_worker_cycles",
    "workflow_monitoring",
    "executive_reporting",
    "scheduled_worker_installation",
    "certification"
  ],
  "next_planned_milestone": "1.5 Knowledge Graph and Reasoning"
}
"@

Write-NewFile ".\config\autonomous-workflows\release-manifest.json" $ReleaseManifest

$WorkerTemplate = @'
{
  "worker_cycle_id": "WKC-YYYYMMDD-HHMMSS-ABC123",
  "started_at": "",
  "completed_at": "",
  "status": "completed",
  "recovered_run_count": 0,
  "processed_run_count": 0,
  "completed_run_count": 0,
  "failed_run_count": 0,
  "waiting_approval_count": 0,
  "runs": []
}
'@

Write-NewFile ".\workspace\templates\autonomous-worker-cycle-template.json" $WorkerTemplate

$WorkerCommon = @'
. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

function Get-AIOfficeAutonomousWorkerPolicy {
    $Root = Get-AIOfficeAutonomousWorkflowRoot

    return Read-AIOfficeAutonomousWorkflowJson `
        -Path (
            Join-Path `
                $Root `
                "config\autonomous-workflows\autonomous-worker-policy.json"
        )
}

function New-AIOfficeAutonomousWorkerCycleId {
    return (
        "WKC-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousMonitoringId {
    return (
        "MON-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}
'@

Write-NewFile ".\scripts\autonomous-workflows\AIOfficeAutonomousWorker.Common.ps1" $WorkerCommon

$WorkerCycle = @'
param(
    [int]$MaximumRuns = 10,
    [int]$MaximumStepsPerRun = 25,
    [switch]$SkipRecovery
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Policy = Get-AIOfficeAutonomousWorkerPolicy
$CycleId = New-AIOfficeAutonomousWorkerCycleId
$StartedAt = (Get-Date).ToString("o")

$Recovered = @()

if (-not $SkipRecovery -and [bool]$Policy.worker.recover_before_processing) {
    $Recovered = @(
        & ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1"
    )
}

$RunFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\runs" `
        -Filter "RUN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$Candidates = New-Object System.Collections.Generic.List[object]

foreach ($File in $RunFiles) {
    $Run = Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName

    if ($null -eq $Run) {
        continue
    }

    if (@("queued","running","waiting") -contains [string]$Run.status) {
        $Candidates.Add($Run)
    }
}

$Candidates = @(
    $Candidates |
        Sort-Object created_at |
        Select-Object -First $MaximumRuns
)

$Results = New-Object System.Collections.Generic.List[object]

foreach ($Run in $Candidates) {
    $BeforeStatus = [string]$Run.status

    try {
        $Updated = & ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1" `
            -RunId ([string]$Run.run_id) `
            -MaximumSteps $MaximumStepsPerRun

        $Results.Add([pscustomobject]@{
            run_id = [string]$Updated.run_id
            before_status = $BeforeStatus
            after_status = [string]$Updated.status
            error = ""
        })
    }
    catch {
        $Results.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            before_status = $BeforeStatus
            after_status = "failed"
            error = $_.Exception.Message
        })
    }
}

$CompletedAt = (Get-Date).ToString("o")
$FailedCount = @(
    $Results | Where-Object { [string]$_.after_status -eq "failed" }
).Count

$Cycle = [ordered]@{
    worker_cycle_id = $CycleId
    started_at = $StartedAt
    completed_at = $CompletedAt
    status = if ($FailedCount -gt 0) { "completed_with_errors" } else { "completed" }
    recovered_run_count = $Recovered.Count
    processed_run_count = $Results.Count
    completed_run_count = @(
        $Results | Where-Object { [string]$_.after_status -eq "completed" }
    ).Count
    failed_run_count = $FailedCount
    waiting_approval_count = @(
        $Results | Where-Object { [string]$_.after_status -eq "waiting_approval" }
    ).Count
    runs = @($Results | ForEach-Object { $_ })
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Cycle `
    -Path (
        ".\workspace\autonomous-workflows\workers\history\" +
        $CycleId +
        ".json"
    )

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host (
    "Autonomous worker cycle completed: " +
    $CycleId +
    " | " +
    $Results.Count.ToString() +
    " run(s)"
) -ForegroundColor Green

return [pscustomobject]$Cycle
'@

Write-NewFile ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousWorkerCycle.ps1" $WorkerCycle

$Monitoring = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Policy = Get-AIOfficeAutonomousWorkerPolicy
$Now = Get-Date
$Runs = New-Object System.Collections.Generic.List[object]
$Warnings = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\runs" `
        -Filter "RUN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Run = Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName

    if ($null -eq $Run) {
        continue
    }

    $Runs.Add($Run)

    $UpdatedAt = [datetime]$Run.updated_at
    $AgeHours = ($Now - $UpdatedAt).TotalHours

    if (
        @("queued","running","waiting") -contains [string]$Run.status -and
        $AgeHours -ge [double]$Policy.monitoring.warning_run_after_hours
    ) {
        $Warnings.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            warning_type = if (
                $AgeHours -ge [double]$Policy.monitoring.stale_run_after_hours
            ) {
                "stale_run"
            }
            else {
                "long_running"
            }
            age_hours = [math]::Round($AgeHours, 2)
            status = [string]$Run.status
        })
    }

    if ([string]$Run.status -eq "waiting_approval") {
        $Warnings.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            warning_type = "waiting_approval"
            age_hours = [math]::Round($AgeHours, 2)
            status = [string]$Run.status
        })
    }

    if ([string]$Run.status -eq "failed") {
        $Warnings.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            warning_type = "failed_run"
            age_hours = [math]::Round($AgeHours, 2)
            status = [string]$Run.status
        })
    }
}

$MonitoringId = New-AIOfficeAutonomousMonitoringId
$Status = if ($Warnings.Count -gt 0) {
    "attention_required"
}
else {
    "healthy"
}

$Report = [ordered]@{
    monitoring_id = $MonitoringId
    generated_at = (Get-Date).ToString("o")
    status = $Status
    active_run_count = @(
        $Runs |
            Where-Object {
                @("queued","running","waiting") -contains [string]$_.status
            }
    ).Count
    waiting_approval_count = @(
        $Runs | Where-Object { [string]$_.status -eq "waiting_approval" }
    ).Count
    failed_run_count = @(
        $Runs | Where-Object { [string]$_.status -eq "failed" }
    ).Count
    completed_run_count = @(
        $Runs | Where-Object { [string]$_.status -eq "completed" }
    ).Count
    warning_count = $Warnings.Count
    warnings = @($Warnings | ForEach-Object { $_ })
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Report `
    -Path (
        ".\workspace\autonomous-workflows\monitoring\" +
        $MonitoringId +
        ".json"
    )

Write-Host (
    "Autonomous workflow monitoring report created: " +
    $MonitoringId
) -ForegroundColor Green

return [pscustomobject]$Report
'@

Write-NewFile ".\scripts\autonomous-workflows\Get-AIOfficeAutonomousWorkflowMonitoring.ps1" $Monitoring

$ExecutiveReport = @'
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
'@

Write-NewFile ".\scripts\autonomous-workflows\New-AIOfficeAutonomousWorkflowReport.ps1" $ExecutiveReport

$ScheduledTask = @'
param(
    [int]$IntervalMinutes = 15,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$TaskName = "AI Office Autonomous Workflow Worker"
$PowerShell = (Get-Command powershell.exe).Source

if ($IntervalMinutes -lt 5) {
    throw "IntervalMinutes must be at least 5."
}

$ScriptPath = Join-Path `
    $Root `
    "scripts\autonomous-workflows\Invoke-AIOfficeAutonomousWorkerCycle.ps1"

$Arguments = (
    '-NoProfile -ExecutionPolicy Bypass -File "' +
    $ScriptPath +
    '"'
)

$Action = New-ScheduledTaskAction `
    -Execute $PowerShell `
    -Argument $Arguments `
    -WorkingDirectory $Root

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At ((Get-Date).AddMinutes(1)) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -RepetitionDuration ([timespan]::MaxValue)

$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

$Existing = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($null -ne $Existing -and -not $Force) {
    Write-Host "Scheduled task already exists: $TaskName" `
        -ForegroundColor Yellow

    return $Existing
}

if ($null -ne $Existing -and $Force) {
    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Runs AI Office autonomous workflow worker cycles." |
    Out-Null

Write-Host "Scheduled task installed: $TaskName" `
    -ForegroundColor Green

return Get-ScheduledTask -TaskName $TaskName
'@

Write-NewFile ".\scripts\autonomous-workflows\Install-AIOfficeAutonomousWorkerTask.ps1" $ScheduledTask

$Certify = @'
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
'@

Write-NewFile ".\scripts\autonomous-workflows\Certify-AIOfficeAutonomousWorkflows.ps1" $Certify

$CompleteTest = @'
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.4 Autonomous Workflows..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-AutonomousTest {
    param(
        [string]$Name,
        [string]$Path
    )

    try {
        & $Path

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "$Name returned exit code $LASTEXITCODE."
        }

        Write-Host ("[PASS] " + $Name) -ForegroundColor Green
    }
    catch {
        Write-Host ("[FAIL] " + $Name) -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $Errors.Add($Name + ": " + $_.Exception.Message)
    }
}

Invoke-AutonomousTest `
    -Name "Part A Autonomous Workflow Architecture" `
    -Path ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflowArchitecture.ps1"

Invoke-AutonomousTest `
    -Name "Part B Autonomous Execution and Recovery" `
    -Path ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousExecution.ps1"

try {
    $Certification = & `
        ".\scripts\autonomous-workflows\Certify-AIOfficeAutonomousWorkflows.ps1"

    if (
        $null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0
    ) {
        throw "Autonomous Workflows certification failed."
    }

    Write-Host (
        "[PASS] Autonomous Workflows certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Autonomous Workflows certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Autonomous Workflows certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Autonomous Workflows error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.4 Autonomous Workflows checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.4 Autonomous Workflows is operational." `
    -ForegroundColor Cyan
'@

Write-NewFile ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflows.ps1" $CompleteTest

$PublishRelease = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$CertificationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\certification" `
        -Filter "CERT-AWF-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
)

if ($CertificationFiles.Count -lt 1) {
    throw "No Autonomous Workflows certification record exists."
}

$Certification = Read-AIOfficeAutonomousWorkflowJson `
    -Path $CertificationFiles[0].FullName

if ($null -eq $Certification -or
    [string]$Certification.status -ne "certified") {
    throw "Latest Autonomous Workflows certification did not pass."
}

$ManifestPath = ".\config\autonomous-workflows\release-manifest.json"
$Manifest = Read-AIOfficeAutonomousWorkflowJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Autonomous Workflows release manifest could not be loaded."
}

$ReleasedAt = (Get-Date).ToString("o")
$Manifest.release_status = "released"

foreach ($Property in @(
    @{ Name = "released_at"; Value = $ReleasedAt },
    @{
        Name = "certification_id"
        Value = [string]$Certification.certification_id
    }
)) {
    if ($null -ne $Manifest.PSObject.Properties[$Property.Name]) {
        $Manifest.($Property.Name) = $Property.Value
    }
    else {
        $Manifest | Add-Member `
            -MemberType NoteProperty `
            -Name $Property.Name `
            -Value $Property.Value
    }
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Manifest `
    -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Autonomous Workflows"
    version = "1.4.0"
    released_at = $ReleasedAt
    status = "released"
    certification_id = [string]$Certification.certification_id
    next_milestone = "1.5 Knowledge Graph and Reasoning"
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $ReleaseRecord `
    -Path (
        ".\workspace\autonomous-workflows\releases\AI-Office-v1.4-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        ".json"
    )

$IdentityPath = ".\config\identity\office.json"

if (Test-Path -LiteralPath $IdentityPath -PathType Leaf) {
    $Identity = Read-AIOfficeAutonomousWorkflowJson -Path $IdentityPath
    $Identity.version = "1.4.0"
    $Identity.codename = "Autonomous Workflows"
    $Identity.updated_at = $ReleasedAt

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Identity `
        -Path $IdentityPath
}

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Read-AIOfficeAutonomousWorkflowJson -Path $VersionPath
    $Version.version = "1.4.0"
    $Version.release_name = "Autonomous Workflows"
    $Version.status = "released"
    $Version.installed_at = $ReleasedAt
    $Version.previous_version = "1.3.0"
    $Version.next_planned_milestone = "1.5 Knowledge Graph and Reasoning"

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Version `
        -Path $VersionPath
}

Write-Host (
    "AI Office v1.4 Autonomous Workflows release recorded: " +
    [string]$Certification.certification_id
) -ForegroundColor Green

return [pscustomobject]$ReleaseRecord
'@

Write-NewFile ".\scripts\autonomous-workflows\Publish-AIOfficeAutonomousWorkflowsRelease.ps1" $PublishRelease

$Guide = @'
# AI Office v1.4 — Autonomous Workflows

AI Office v1.4 adds persistent, restart-safe, human-supervised autonomous workflow execution.

## Delivered

### Part A — Architecture
- Executive goals
- Autonomous plans
- Persistent runs
- Dependencies
- Approval policy
- Retry policy
- Checkpoint policy
- Recovery architecture

### Part B — Execution and Recovery
- Step execution
- Memory recall
- Department dispatch
- Message Bus dispatch
- OpenClaw dispatch
- Human approval gates
- Checkpoints
- Retries
- Failures
- Restart recovery

### Part C — Runtime and Release
- Worker cycles
- Background processing
- Monitoring
- Stale-run warnings
- Executive reports
- Scheduled-task installation
- Complete certification
- Release publication

## Complete validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflows.ps1"
```

Expected ending:

```text
All AI Office v1.4 Autonomous Workflows checks passed.
AI Office v1.4 Autonomous Workflows is operational.
```

## Publish release

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Publish-AIOfficeAutonomousWorkflowsRelease.ps1"
```

## Install background worker

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Install-AIOfficeAutonomousWorkerTask.ps1" `
    -IntervalMinutes 15
```

## Run worker manually

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousWorkerCycle.ps1"
```

## Generate monitoring report

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Get-AIOfficeAutonomousWorkflowMonitoring.ps1"
```

## Next milestone

AI Office v1.5 will introduce Knowledge Graph and Reasoning.
'@

Write-NewFile ".\docs\AI-Office-v1.4-Autonomous-Workflows-Guide.md" $Guide

$ReleaseNotes = @'
# AI Office v1.4 Release Notes

## Release name

Autonomous Workflows

## Added

- Executive goals
- Persistent plans and runs
- Step dependencies
- Memory recall
- Department, Message Bus, and OpenClaw dispatch
- Human approval gates
- Checkpoints and retries
- Restart recovery
- Autonomous worker cycles
- Monitoring and executive reporting
- Scheduled background worker
- Certification and release publication

## Next

AI Office v1.5 — Knowledge Graph and Reasoning
'@

Write-NewFile ".\docs\AI-Office-v1.4-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.4.0"
    $Version.release_name = "Autonomous Workflows"
    $Version.status = "part_c_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.5 Knowledge Graph and Reasoning"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.4 Part C" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part C JSON files..." -ForegroundColor Cyan

@(
    ".\config\autonomous-workflows\autonomous-worker-policy.json",
    ".\config\autonomous-workflows\worker-cycle-schema.json",
    ".\config\autonomous-workflows\monitoring-schema.json",
    ".\config\autonomous-workflows\release-manifest.json",
    ".\workspace\templates\autonomous-worker-cycle-template.json"
) | ForEach-Object {
    Get-Content -LiteralPath $_ -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] $_" -ForegroundColor Green
}

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.4-Part-C-Worker-Runtime-Monitoring-Release-Install.ps1"

    if (
        $Source -and
        (Test-Path -LiteralPath $Source -PathType Leaf) -and
        [System.IO.Path]::GetFullPath($Source) -ne
        [System.IO.Path]::GetFullPath($Destination)
    ) {
        Copy-Item `
            -LiteralPath $Source `
            -Destination $Destination `
            -Force

        Write-Host "[COPIED ] Installer saved to $Destination" `
            -ForegroundColor Green
    }
}
catch {
    Write-Host (
        "[WARNING] Installer copy was not completed: " +
        $_.Exception.Message
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "AI Office v1.4 Part C installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run complete validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflows.ps1"'
Write-Host ""
