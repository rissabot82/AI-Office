param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentExecutionId,
    [ValidateSet("lesson","template","playbook","decision","metric")]
    [string]$KnowledgeType = "lesson",
    [double]$Confidence = 0.80
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\departments\$Department\execution" `
    ($DepartmentExecutionId + ".json")

$Execution = Read-AIOfficeDepartmentJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Department execution not found: $DepartmentExecutionId"
}

if ([string]$Execution.status -ne "completed") {
    throw "Only completed department executions can create knowledge."
}

. ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1"
$PlanRecord = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId ([string]$Execution.department_plan_id)

$Content = [ordered]@{
    objective = [string]$PlanRecord.objective
    execution_mode = [string]$Execution.execution_mode
    steps = @($PlanRecord.steps)
    result = $Execution.result
}

$Source = [ordered]@{
    type = "department_execution"
    department_execution_id = $DepartmentExecutionId
    department_plan_id = [string]$Execution.department_plan_id
    work_item_id = [string]$Execution.work_item_id
}

$Knowledge = & ".\scripts\departments\New-AIOfficeDepartmentKnowledge.ps1" `
    -Department $Department `
    -KnowledgeType $KnowledgeType `
    -Title ([string]$PlanRecord.title) `
    -Summary ([string]$Execution.result.summary) `
    -ContentJson ($Content | ConvertTo-Json -Depth 30 -Compress) `
    -SourceJson ($Source | ConvertTo-Json -Depth 20 -Compress) `
    -Confidence $Confidence

& ".\scripts\departments\Add-AIOfficeDepartmentLearning.ps1" `
    -Department $Department `
    -EventType "success" `
    -SourceId $DepartmentExecutionId `
    -Summary "Knowledge captured from successful department execution." `
    -KnowledgeId ([string]$Knowledge.knowledge_id) |
    Out-Null

return $Knowledge
