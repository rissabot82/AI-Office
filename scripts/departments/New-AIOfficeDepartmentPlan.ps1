param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$WorkItemId,
    [ValidateSet(
        "internal_reasoning",
        "message_bus",
        "openclaw_bridge",
        "human_approval"
    )]
    [string]$ExecutionMode = "internal_reasoning"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$WorkItem = Get-AIOfficeDepartmentWorkItem `
    -Department $Department `
    -WorkItemId $WorkItemId

$PlanId = New-AIOfficeDepartmentPlanId
$Now = (Get-Date).ToString("o")

$Steps = New-Object System.Collections.Generic.List[object]
$StepNumber = 1

foreach ($Deliverable in @($WorkItem.deliverables)) {
    $Steps.Add([ordered]@{
        step_number = $StepNumber
        title = [string]$Deliverable
        owner = $Department
        execution_mode = $ExecutionMode
        status = "pending"
    })

    $StepNumber++
}

if ($Steps.Count -lt 1) {
    $Steps.Add([ordered]@{
        step_number = 1
        title = "Complete assigned department work"
        owner = $Department
        execution_mode = $ExecutionMode
        status = "pending"
    })
}

$Plan = [ordered]@{
    department_plan_id = $PlanId
    department = $Department
    work_item_id = $WorkItemId
    title = [string]$WorkItem.title
    objective = [string]$WorkItem.objective
    execution_mode = $ExecutionMode
    status = "draft"
    priority = [string]$WorkItem.priority
    risk_level = [string]$WorkItem.risk_level
    approval_status = [string]$WorkItem.approval_status
    workflow_id = [string]$WorkItem.workflow_id
    conversation_id = [string]$WorkItem.conversation_id
    correlation_id = [string]$WorkItem.correlation_id
    steps = @($Steps | ForEach-Object { $_ })
    created_at = $Now
    updated_at = $Now
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department plan created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\departments\$Department\plans" `
    ($PlanId + ".json")

Write-AIOfficeDepartmentJson -Value $Plan -Path $Path

Write-Host "Department plan created: $PlanId" `
    -ForegroundColor Green

return [pscustomobject]$Plan
