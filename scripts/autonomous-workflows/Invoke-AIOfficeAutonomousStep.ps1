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

    "human_approval" {
        $Summary = "Human approval completed for workflow step."
        $Payload = [ordered]@{
            approved = $true
            approval_status = [string]$Step.approval_status
            approved_step = [string]$Step.title
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

