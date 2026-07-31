# ============================================================
# AI Office v1.4 - Part B
# Autonomous Execution, Approval, Retry, Checkpoint, and Recovery
# Repository: E:\AI\AI-Office
# Requires: AI Office v1.4 Part A
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\autonomous-workflows\autonomous-workflow-policy.json",
    ".\scripts\autonomous-workflows\AIOfficeAutonomousWorkflows.Common.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousGoal.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousPlan.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousRun.ps1",
    ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1",
    ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1",
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.4 Part A is required. Missing: $RequiredPath"
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
    ".\workspace\autonomous-workflows\step-results",
    ".\workspace\autonomous-workflows\dispatch",
    ".\workspace\autonomous-workflows\recovery",
    ".\workspace\autonomous-workflows\workers"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$ExecutionPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.4.0",
  "part": "B",
  "execution": {
    "persist_before_step": true,
    "persist_after_step": true,
    "stop_on_failure": true,
    "allow_resume": true,
    "maximum_steps_per_cycle": 25
  },
  "approval": {
    "waiting_status": "waiting_approval",
    "approved_status": "approved",
    "rejected_status": "rejected"
  },
  "retry": {
    "enabled": true,
    "default_max_attempts": 3,
    "default_delay_seconds": 1,
    "backoff_multiplier": 2.0,
    "retryable_step_types": [
      "chief_of_staff",
      "department",
      "message_bus",
      "openclaw_bridge",
      "memory_recall",
      "report"
    ]
  },
  "recovery": {
    "resume_statuses": [
      "queued",
      "running",
      "waiting",
      "waiting_approval"
    ],
    "orphaned_after_hours": 24,
    "recover_from_latest_checkpoint": true
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\autonomous-workflows\autonomous-execution-policy.json" $ExecutionPolicy

$StepResultSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-step-result-schema.json",
  "title": "AI Office Autonomous Step Result",
  "type": "object",
  "required": [
    "step_result_id",
    "run_id",
    "step_id",
    "step_type",
    "status",
    "summary",
    "created_at"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\step-result-schema.json" $StepResultSchema

$ApprovalSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-approval-schema.json",
  "title": "AI Office Autonomous Approval",
  "type": "object",
  "required": [
    "approval_id",
    "run_id",
    "step_id",
    "status",
    "decision",
    "created_at",
    "created_by"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\approval-schema.json" $ApprovalSchema

$RecoverySchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/autonomous-recovery-schema.json",
  "title": "AI Office Autonomous Recovery Record",
  "type": "object",
  "required": [
    "recovery_id",
    "run_id",
    "previous_status",
    "recovered_status",
    "created_at"
  ]
}
'@

Write-NewFile ".\config\autonomous-workflows\recovery-schema.json" $RecoverySchema

$StepResultTemplate = @'
{
  "step_result_id": "SR-YYYYMMDD-HHMMSS-ABC123",
  "run_id": "RUN-YYYYMMDD-HHMMSS-ABC123",
  "step_id": "STEP-001-ABC123",
  "step_type": "department",
  "status": "completed",
  "summary": "",
  "payload": {},
  "created_at": ""
}
'@

Write-NewFile ".\workspace\templates\autonomous-step-result-template.json" $StepResultTemplate

$ExecutionCommon = @'
. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

function Get-AIOfficeAutonomousExecutionPolicy {
    $Root = Get-AIOfficeAutonomousWorkflowRoot

    return Read-AIOfficeAutonomousWorkflowJson `
        -Path (
            Join-Path `
                $Root `
                "config\autonomous-workflows\autonomous-execution-policy.json"
        )
}

function New-AIOfficeAutonomousStepResultId {
    return (
        "SR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousApprovalId {
    return (
        "APRWF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAutonomousRecoveryId {
    return (
        "REC-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeAutonomousRun {
    param([Parameter(Mandatory=$true)][string]$RunId)

    $Root = Get-AIOfficeAutonomousWorkflowRoot
    $Path = Join-Path `
        $Root `
        ("workspace\autonomous-workflows\runs\" + $RunId + ".json")

    $Run = Read-AIOfficeAutonomousWorkflowJson -Path $Path

    if ($null -eq $Run) {
        throw "Autonomous run not found: $RunId"
    }

    return $Run
}

function Save-AIOfficeAutonomousRun {
    param([Parameter(Mandatory=$true)]$Run)

    $Root = Get-AIOfficeAutonomousWorkflowRoot

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Run `
        -Path (
            Join-Path `
                $Root `
                ("workspace\autonomous-workflows\runs\" + [string]$Run.run_id + ".json")
        )
}

function Save-AIOfficeAutonomousPlan {
    param([Parameter(Mandatory=$true)]$Plan)

    $Root = Get-AIOfficeAutonomousWorkflowRoot

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Plan `
        -Path (
            Join-Path `
                $Root `
                (
                    "workspace\autonomous-workflows\plans\" +
                    [string]$Plan.autonomous_plan_id +
                    ".json"
                )
        )
}

function Test-AIOfficeAutonomousStepDependencies {
    param(
        [Parameter(Mandatory=$true)]$Step,
        [Parameter(Mandatory=$true)]$Plan
    )

    $Dependencies = @($Step.depends_on)

    if ($Dependencies.Count -lt 1) {
        return $true
    }

    foreach ($DependencyId in $Dependencies) {
        $Dependency = @(
            $Plan.steps |
                Where-Object { [string]$_.step_id -eq [string]$DependencyId }
        ) | Select-Object -First 1

        if ($null -eq $Dependency -or [string]$Dependency.status -ne "completed") {
            return $false
        }
    }

    return $true
}
'@

Write-NewFile ".\scripts\autonomous-workflows\AIOfficeAutonomousExecution.Common.ps1" $ExecutionCommon

$ApprovalScript = @'
param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$StepId,
    [ValidateSet("approved","rejected")]
    [string]$Status,
    [Parameter(Mandatory=$true)][string]$Decision,
    [string]$CreatedBy = "Clarissa Schmidtberger"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Run = Get-AIOfficeAutonomousRun -RunId $RunId
$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId ([string]$Run.autonomous_plan_id)

$Step = @(
    $Plan.steps |
        Where-Object { [string]$_.step_id -eq $StepId }
) | Select-Object -First 1

if ($null -eq $Step) {
    throw "Workflow step not found: $StepId"
}

$ApprovalId = New-AIOfficeAutonomousApprovalId
$Now = (Get-Date).ToString("o")

$Approval = [ordered]@{
    approval_id = $ApprovalId
    run_id = $RunId
    step_id = $StepId
    status = $Status
    decision = $Decision
    created_at = $Now
    created_by = $CreatedBy
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Approval `
    -Path ".\workspace\autonomous-workflows\approvals\$ApprovalId.json"

$Step.status = if ($Status -eq "approved") { "pending" } else { "rejected" }

if ($null -eq $Step.PSObject.Properties["approval_status"]) {
    $Step | Add-Member `
        -MemberType NoteProperty `
        -Name approval_status `
        -Value $Status
}
else {
    $Step.approval_status = $Status
}

$Plan.updated_at = $Now
Save-AIOfficeAutonomousPlan -Plan $Plan

$Run.status = if ($Status -eq "approved") { "running" } else { "failed" }
$Run.updated_at = $Now
Save-AIOfficeAutonomousRun -Run $Run

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host (
    "Autonomous workflow approval recorded: " +
    $ApprovalId +
    " | " +
    $Status
) -ForegroundColor Green

return [pscustomobject]$Approval
'@

Write-NewFile ".\scripts\autonomous-workflows\Set-AIOfficeAutonomousApproval.ps1" $ApprovalScript

$InvokeStep = @'
param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$StepId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Run = Get-AIOfficeAutonomousRun -RunId $RunId
$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId ([string]$Run.autonomous_plan_id)

$Step = @(
    $Plan.steps |
        Where-Object { [string]$_.step_id -eq $StepId }
) | Select-Object -First 1

if ($null -eq $Step) {
    throw "Workflow step not found: $StepId"
}

if (-not (Test-AIOfficeAutonomousStepDependencies -Step $Step -Plan $Plan)) {
    throw "Workflow step dependencies are not complete."
}

if ([string]$Step.status -eq "completed") {
    return [pscustomobject]@{
        step_result_id = ""
        run_id = $RunId
        step_id = $StepId
        step_type = [string]$Step.step_type
        status = "completed"
        summary = "Step was already completed."
        payload = [ordered]@{}
        created_at = (Get-Date).ToString("o")
    }
}

if (
    [string]$Step.step_type -eq "human_approval" -and
    (
        $null -eq $Step.PSObject.Properties["approval_status"] -or
        [string]$Step.approval_status -ne "approved"
    )
) {
    $Step.status = "waiting_approval"
    $Run.status = "waiting_approval"
    $Run.updated_at = (Get-Date).ToString("o")
    $Plan.updated_at = $Run.updated_at

    Save-AIOfficeAutonomousPlan -Plan $Plan
    Save-AIOfficeAutonomousRun -Run $Run

    Write-Host "Workflow step waiting for approval: $StepId" `
        -ForegroundColor Yellow

    return [pscustomobject]@{
        step_result_id = ""
        run_id = $RunId
        step_id = $StepId
        step_type = [string]$Step.step_type
        status = "waiting_approval"
        summary = "Human approval is required."
        payload = [ordered]@{}
        created_at = (Get-Date).ToString("o")
    }
}

$BeforeState = [ordered]@{
    run_status = [string]$Run.status
    step_status = [string]$Step.status
    current_step = [int]$Run.current_step
}

& ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1" `
    -RunId $RunId `
    -StepId $StepId `
    -Stage "before" `
    -StateJson ($BeforeState | ConvertTo-Json -Depth 20 -Compress) |
    Out-Null

$Step.status = "running"
$Step.attempt_count = [int]$Step.attempt_count + 1
$Run.status = "running"
$Run.started_at = if ($null -eq $Run.started_at) {
    (Get-Date).ToString("o")
}
else {
    $Run.started_at
}
$Run.updated_at = (Get-Date).ToString("o")
$Plan.updated_at = $Run.updated_at

Save-AIOfficeAutonomousPlan -Plan $Plan
Save-AIOfficeAutonomousRun -Run $Run

$Summary = ""
$Payload = [ordered]@{}

switch ([string]$Step.step_type) {
    "chief_of_staff" {
        $Summary = "Chief of Staff step completed: " + [string]$Step.title
        $Payload = [ordered]@{
            owner = [string]$Step.owner
        }
    }

    "department" {
        $Department = [string]$Step.department

        if ([string]::IsNullOrWhiteSpace($Department)) {
            $Department = [string]$Step.owner
        }

        $MessagePayload = [ordered]@{
            objective = [string]$Plan.objective
            deliverables = @([string]$Step.title)
            risk_level = [string]$Plan.risk_level
            approval_status = [string]$Plan.approval_status
            autonomous_run_id = $RunId
            autonomous_step_id = $StepId
        }

        $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
            -From "autonomous-workflow-engine" `
            -To $Department `
            -MessageType "handoff" `
            -Priority ([string]$Plan.priority) `
            -Subject ([string]$Step.title) `
            -ConversationTopic "AUTONOMOUS-WORKFLOW" `
            -Queue "outbox" `
            -PayloadJson ($MessagePayload | ConvertTo-Json -Depth 20 -Compress)

        $Summary = "Department work dispatched to $Department."
        $Payload = [ordered]@{
            department = $Department
            message_id = [string]$Message.message_id
        }
    }

    "message_bus" {
        $MessagePayload = [ordered]@{
            objective = [string]$Plan.objective
            autonomous_run_id = $RunId
            autonomous_step_id = $StepId
        }

        $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
            -From "autonomous-workflow-engine" `
            -To ([string]$Step.owner) `
            -MessageType "request" `
            -Priority ([string]$Plan.priority) `
            -Subject ([string]$Step.title) `
            -ConversationTopic "AUTONOMOUS-WORKFLOW" `
            -Queue "outbox" `
            -PayloadJson ($MessagePayload | ConvertTo-Json -Depth 20 -Compress)

        $Summary = "Message Bus request created."
        $Payload = [ordered]@{
            message_id = [string]$Message.message_id
        }
    }

    "openclaw_bridge" {
        $BridgePayload = [ordered]@{
            action_type = "agent_task"
            objective = [string]$Plan.objective
            prompt = [string]$Step.title
            autonomous_run_id = $RunId
            autonomous_step_id = $StepId
            risk_level = [string]$Plan.risk_level
            approval_status = [string]$Plan.approval_status
        }

        $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
            -From "autonomous-workflow-engine" `
            -To "bridge" `
            -MessageType "execution_request" `
            -Priority ([string]$Plan.priority) `
            -Subject ([string]$Step.title) `
            -ConversationTopic "AUTONOMOUS-OPENCLAW" `
            -Queue "outbox" `
            -PayloadJson ($BridgePayload | ConvertTo-Json -Depth 20 -Compress)

        $Summary = "OpenClaw Bridge execution request created."
        $Payload = [ordered]@{
            message_id = [string]$Message.message_id
        }
    }

    "memory_recall" {
        $Packet = & ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" `
            -Query ([string]$Plan.objective) `
            -RequestedBy "autonomous-workflow-engine" `
            -Limit 10

        $Summary = "Memory context packet generated."
        $Payload = [ordered]@{
            context_packet_id = [string]$Packet.context_packet_id
            memory_count = [int]$Packet.memory_count
        }
    }

    "wait" {
        $Summary = "Wait step acknowledged."
        $Payload = [ordered]@{
            wait_complete = $true
        }
    }

    "report" {
        $Summary = "Autonomous workflow report step completed."
        $Payload = [ordered]@{
            title = [string]$Plan.title
            objective = [string]$Plan.objective
        }
    }

    default {
        throw "Unsupported autonomous workflow step type: $($Step.step_type)"
    }
}

$CompletedAt = (Get-Date).ToString("o")
$Step.status = "completed"
$Step.result = [ordered]@{
    summary = $Summary
    payload = $Payload
    completed_at = $CompletedAt
}

$Run.current_step = [int]$Step.step_number
$Run.updated_at = $CompletedAt
$Plan.updated_at = $CompletedAt

$ResultId = New-AIOfficeAutonomousStepResultId
$Result = [ordered]@{
    step_result_id = $ResultId
    run_id = $RunId
    step_id = $StepId
    step_type = [string]$Step.step_type
    status = "completed"
    summary = $Summary
    payload = $Payload
    created_at = $CompletedAt
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Result `
    -Path ".\workspace\autonomous-workflows\step-results\$ResultId.json"

Save-AIOfficeAutonomousPlan -Plan $Plan
Save-AIOfficeAutonomousRun -Run $Run

$AfterState = [ordered]@{
    run_status = [string]$Run.status
    step_status = [string]$Step.status
    current_step = [int]$Run.current_step
    step_result_id = $ResultId
}

& ".\scripts\autonomous-workflows\New-AIOfficeAutonomousCheckpoint.ps1" `
    -RunId $RunId `
    -StepId $StepId `
    -Stage "after" `
    -StateJson ($AfterState | ConvertTo-Json -Depth 20 -Compress) |
    Out-Null

Write-Host "Autonomous workflow step completed: $StepId" `
    -ForegroundColor Green

return [pscustomobject]$Result
'@

Write-NewFile ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousStep.ps1" $InvokeStep

$InvokeRun = @'
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
'@

Write-NewFile ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1" $InvokeRun

$Retry = @'
param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$StepId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Run = Get-AIOfficeAutonomousRun -RunId $RunId
$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId ([string]$Run.autonomous_plan_id)

$Step = @(
    $Plan.steps |
        Where-Object { [string]$_.step_id -eq $StepId }
) | Select-Object -First 1

if ($null -eq $Step) {
    throw "Workflow step not found: $StepId"
}

if ([int]$Step.attempt_count -ge [int]$Step.max_attempts) {
    throw "Maximum retry attempts reached for step $StepId."
}

$RetryId = (
    "RTY-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss") +
    "-" +
    ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
)

$Retry = [ordered]@{
    retry_id = $RetryId
    run_id = $RunId
    step_id = $StepId
    attempt_number = ([int]$Step.attempt_count + 1)
    created_at = (Get-Date).ToString("o")
    status = "queued"
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Retry `
    -Path ".\workspace\autonomous-workflows\retries\$RetryId.json"

$Step.status = "pending"
$Plan.status = "running"
$Plan.updated_at = (Get-Date).ToString("o")
Save-AIOfficeAutonomousPlan -Plan $Plan

$Run.status = "running"
$Run.updated_at = (Get-Date).ToString("o")
Save-AIOfficeAutonomousRun -Run $Run

Write-Host "Autonomous workflow retry queued: $RetryId" `
    -ForegroundColor Green

return [pscustomobject]$Retry
'@

Write-NewFile ".\scripts\autonomous-workflows\Retry-AIOfficeAutonomousStep.ps1" $Retry

$Recovery = @'
param(
    [string]$RunId = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Policy = Get-AIOfficeAutonomousExecutionPolicy
$Runs = New-Object System.Collections.Generic.List[object]

if ($RunId) {
    $Runs.Add((Get-AIOfficeAutonomousRun -RunId $RunId))
}
else {
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath ".\workspace\autonomous-workflows\runs" `
            -Filter "RUN-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Run = Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName

        if (
            $null -ne $Run -and
            @($Policy.recovery.resume_statuses) -contains [string]$Run.status
        ) {
            $Runs.Add($Run)
        }
    }
}

$Recovered = New-Object System.Collections.Generic.List[object]

foreach ($Run in $Runs) {
    $PreviousStatus = [string]$Run.status
    $RecoveredStatus = $PreviousStatus

    if ($PreviousStatus -in @("queued","running","waiting")) {
        $RecoveredStatus = "running"
    }

    if ($PreviousStatus -eq "waiting_approval") {
        $RecoveredStatus = "waiting_approval"
    }

    $Run.status = $RecoveredStatus
    $Run.updated_at = (Get-Date).ToString("o")
    Save-AIOfficeAutonomousRun -Run $Run

    $RecoveryId = New-AIOfficeAutonomousRecoveryId
    $Record = [ordered]@{
        recovery_id = $RecoveryId
        run_id = [string]$Run.run_id
        previous_status = $PreviousStatus
        recovered_status = $RecoveredStatus
        checkpoint_id = [string]$Run.last_checkpoint_id
        created_at = (Get-Date).ToString("o")
    }

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Record `
        -Path ".\workspace\autonomous-workflows\recovery\$RecoveryId.json"

    $Recovered.Add([pscustomobject]$Record)
}

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host (
    "Autonomous workflow recovery completed: " +
    $Recovered.Count.ToString() +
    " run(s)"
) -ForegroundColor Green

return @($Recovered | ForEach-Object { $_ })
'@

Write-NewFile ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1" $Recovery

$Test = @'
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
'@

Write-NewFile ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousExecution.ps1" $Test

$Guide = @'
# AI Office v1.4 Part B — Autonomous Execution and Recovery

Part B turns persistent workflow plans into executable, approval-aware, checkpointed, restart-safe runs.

## Added

- Autonomous step execution
- Dependency checks
- Chief of Staff steps
- Department dispatch
- Message Bus dispatch
- OpenClaw Bridge dispatch
- Memory recall
- Wait steps
- Report steps
- Human approval gates
- Step results
- Before/after checkpoints
- Failure records
- Retry records
- Run recovery
- Restart-safe continuation
- Full validation

## Validate

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousExecution.ps1"
```

Expected result:

```text
All AI Office v1.4 Part B Autonomous Execution and Recovery checks passed.
```

## Execute a run

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1" `
    -RunId "RUN-..." `
    -MaximumSteps 25
```

## Approve a waiting step

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Set-AIOfficeAutonomousApproval.ps1" `
    -RunId "RUN-..." `
    -StepId "STEP-..." `
    -Status "approved" `
    -Decision "Proceed."
```

## Recover runs after restart

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1"
```

## Next

Part C will add background scheduling, autonomous worker cycles, workflow monitoring, executive reporting, full certification, and v1.4 release publication.
'@

Write-NewFile ".\docs\AI-Office-v1.4-Part-B-Autonomous-Execution-Recovery.md" $Guide

$ReleaseNotes = @'
# AI Office v1.4 Part B Release Notes

## Release

Autonomous Execution and Recovery

## Added

- Autonomous step execution
- Department and Message Bus dispatch
- OpenClaw Bridge dispatch
- Memory recall
- Human approval gates
- Checkpoints
- Retries
- Failures
- Recovery
- Restart-safe continuation
- Validation suite

## Next

v1.4 Part C — Worker Runtime, Monitoring, Certification, and Release
'@

Write-NewFile ".\docs\AI-Office-v1.4-Part-B-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.4.0"
    $Version.release_name = "Autonomous Workflows"
    $Version.status = "part_b_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.4 Part C Worker Runtime and Release"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to v1.4 Part B" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part B JSON files..." -ForegroundColor Cyan

@(
    ".\config\autonomous-workflows\autonomous-execution-policy.json",
    ".\config\autonomous-workflows\step-result-schema.json",
    ".\config\autonomous-workflows\approval-schema.json",
    ".\config\autonomous-workflows\recovery-schema.json",
    ".\workspace\templates\autonomous-step-result-template.json"
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
        "Installers\AI-Office-v1.4-Part-B-Autonomous-Execution-Recovery-Install.ps1"

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
Write-Host "AI Office v1.4 Part B installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousExecution.ps1"'
Write-Host ""
