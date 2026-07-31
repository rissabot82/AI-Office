param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentExecutionId,
    [string]$ResultSummary = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\departments\$Department\execution" `
    ($DepartmentExecutionId + ".json")

$Execution = Read-AIOfficeDepartmentJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Department execution not found: $DepartmentExecutionId"
}

$Plan = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId ([string]$Execution.department_plan_id)

$WorkItem = Get-AIOfficeDepartmentWorkItem `
    -Department $Department `
    -WorkItemId ([string]$Execution.work_item_id)

$Now = (Get-Date).ToString("o")
$Execution.status = "running"
$Execution.started_at = $Now
$Execution.updated_at = $Now

Write-AIOfficeDepartmentJson `
    -Value $Execution `
    -Path $ExecutionPath

switch ([string]$Execution.execution_mode) {
    "internal_reasoning" {
        if ([string]::IsNullOrWhiteSpace($ResultSummary)) {
            $ResultSummary = (
                "Department work completed through internal reasoning for: " +
                [string]$Plan.title
            )
        }
    }

    "message_bus" {
        if ([string]::IsNullOrWhiteSpace($ResultSummary)) {
            $ResultSummary = "Department Message Bus coordination completed."
        }
    }

    "openclaw_bridge" {
        $Payload = [ordered]@{
            action_type = "agent_task"
            objective = [string]$Plan.objective
            deliverables = @($WorkItem.deliverables)
            risk_level = [string]$WorkItem.risk_level
            approval_status = [string]$WorkItem.approval_status
            prompt = (
                "Complete this department objective: " +
                [string]$Plan.objective
            )
        }

        $BridgeMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
            -From $Department `
            -To "bridge" `
            -MessageType "execution_request" `
            -Priority ([string]$WorkItem.priority) `
            -Subject ([string]$Plan.title) `
            -ConversationTopic "DEPARTMENT-OPENCLAW" `
            -Queue "outbox" `
            -PayloadJson ($Payload | ConvertTo-Json -Depth 20 -Compress)

        $ResultSummary = (
            "OpenClaw execution request dispatched: " +
            [string]$BridgeMessage.message_id
        )
    }

    "human_approval" {
        if ([string]$WorkItem.approval_status -ne "approved") {
            throw "Department execution requires human approval."
        }

        if ([string]::IsNullOrWhiteSpace($ResultSummary)) {
            $ResultSummary = "Human-approved department execution completed."
        }
    }
}

$CompletedAt = (Get-Date).ToString("o")
$Execution.status = "completed"
$Execution.completed_at = $CompletedAt
$Execution.updated_at = $CompletedAt
$Execution.result = [ordered]@{
    summary = $ResultSummary
    completed_by = $Department
}

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Execution.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $CompletedAt
    action = "completed"
    actor = $Department
    details = $ResultSummary
})

$Execution.history = @($History | ForEach-Object { $_ })

Write-AIOfficeDepartmentJson `
    -Value $Execution `
    -Path $ExecutionPath

$Plan.status = "completed"
$Plan.updated_at = $CompletedAt

foreach ($Step in @($Plan.steps)) {
    $Step.status = "completed"
}

Write-AIOfficeDepartmentJson `
    -Value $Plan `
    -Path ".\workspace\departments\$Department\plans\$($Plan.department_plan_id).json"

$WorkItem.status = "completed"
$WorkItem.updated_at = $CompletedAt

if ($null -eq $WorkItem.PSObject.Properties["completed_at"]) {
    $WorkItem | Add-Member `
        -MemberType NoteProperty `
        -Name completed_at `
        -Value $CompletedAt
}
else {
    $WorkItem.completed_at = $CompletedAt
}

if ($null -eq $WorkItem.PSObject.Properties["result_summary"]) {
    $WorkItem | Add-Member `
        -MemberType NoteProperty `
        -Name result_summary `
        -Value $ResultSummary
}
else {
    $WorkItem.result_summary = $ResultSummary
}

Write-AIOfficeDepartmentJson `
    -Value $WorkItem `
    -Path ".\workspace\departments\$Department\work\$($WorkItem.work_item_id).json"

return $Execution
