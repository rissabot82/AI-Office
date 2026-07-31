param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentExecutionId
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

if ([string]$Execution.status -ne "completed") {
    throw "Only completed executions can publish results."
}

$Plan = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId ([string]$Execution.department_plan_id)

$Payload = [ordered]@{
    department = $Department
    department_execution_id = $DepartmentExecutionId
    department_plan_id = [string]$Execution.department_plan_id
    work_item_id = [string]$Execution.work_item_id
    status = [string]$Execution.status
    summary = [string]$Execution.result.summary
}

$Arguments = @{
    From = $Department
    To = "chief-of-staff"
    MessageType = "execution_result"
    Subject = ("Department result: " + [string]$Plan.title)
    Priority = [string]$Plan.priority
    WorkflowId = [string]$Plan.workflow_id
    Queue = "inbox"
    PayloadJson = ($Payload | ConvertTo-Json -Depth 20 -Compress)
}

if (-not [string]::IsNullOrWhiteSpace([string]$Plan.correlation_id)) {
    $Arguments.CorrelationId = [string]$Plan.correlation_id
}

if (-not [string]::IsNullOrWhiteSpace([string]$Plan.conversation_id)) {
    $Arguments.ConversationId = [string]$Plan.conversation_id
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" @Arguments

$ResultRecord = [ordered]@{
    result_id = (
        "DRS-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    department = $Department
    department_execution_id = $DepartmentExecutionId
    message_id = [string]$Message.message_id
    published_at = (Get-Date).ToString("o")
    status = "published"
}

$Path = Join-Path `
    ".\workspace\departments\$Department\results" `
    ([string]$ResultRecord.result_id + ".json")

Write-AIOfficeDepartmentJson `
    -Value $ResultRecord `
    -Path $Path

Write-Host (
    "Department result published: " +
    [string]$Message.message_id
) -ForegroundColor Green

return [pscustomobject]$ResultRecord
