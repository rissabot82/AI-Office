param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$DepartmentPlanId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Plan = Get-AIOfficeDepartmentPlan `
    -Department $Department `
    -DepartmentPlanId $DepartmentPlanId

$ExecutionId = New-AIOfficeDepartmentExecutionId
$Now = (Get-Date).ToString("o")

$Execution = [ordered]@{
    department_execution_id = $ExecutionId
    department = $Department
    department_plan_id = $DepartmentPlanId
    work_item_id = [string]$Plan.work_item_id
    execution_mode = [string]$Plan.execution_mode
    status = "queued"
    created_at = $Now
    updated_at = $Now
    started_at = $null
    completed_at = $null
    result = $null
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department execution created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\departments\$Department\execution" `
    ($ExecutionId + ".json")

Write-AIOfficeDepartmentJson `
    -Value $Execution `
    -Path $Path

$Plan.status = "queued"
$Plan.updated_at = $Now

Write-AIOfficeDepartmentJson `
    -Value $Plan `
    -Path ".\workspace\departments\$Department\plans\$DepartmentPlanId.json"

Write-Host "Department execution created: $ExecutionId" `
    -ForegroundColor Green

return [pscustomobject]$Execution
