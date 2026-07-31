param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowId,

    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$workflowPath = Join-Path `
    ".\workspace\workflows\$WorkflowId" `
    "workflow.json"

if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
    throw "Workflow not found: $WorkflowId"
}

$workflow = Get-Content `
    -LiteralPath $workflowPath `
    -Raw |
    ConvertFrom-Json

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AI Office Workflow" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Workflow ID:    $($workflow.workflow_id)"
Write-Host "Title:          $($workflow.title)"
Write-Host "Status:         $($workflow.status)"
Write-Host "Owner:          $($workflow.owner_agent)"
Write-Host "Department:     $($workflow.lead_department)"
Write-Host "Approval:       $($workflow.approval_status)"
Write-Host "Due date:       $($workflow.due_date)"
Write-Host (
    "Progress:       {0}% ({1}/{2} complete)" -f
    $workflow.progress.percentage,
    $workflow.progress.completed_tasks,
    $workflow.progress.total_tasks
)
Write-Host "Blocked tasks:  $($workflow.progress.blocked_tasks)"
Write-Host ""

$tasks = @(
    $workflow.tasks |
    Sort-Object sequence, task_id
)

if ($tasks.Count -eq 0) {
    Write-Host "No child tasks have been added." -ForegroundColor Yellow
    exit 0
}

$taskRows = foreach ($task in $tasks) {
    [PSCustomObject]@{
        Seq = $task.sequence
        TaskId = $task.task_id
        Status = $task.status
        Agent = $task.assigned_agent
        Required = $task.required
        Dependencies = (@($task.dependencies) -join ", ")
        Title = $task.title
    }
}

$taskRows | Format-Table -AutoSize

if ($Detailed) {
    Write-Host ""
    Write-Host "Dependency details:" -ForegroundColor Cyan

    foreach ($task in $tasks) {
        Write-Host ""
        Write-Host "$($task.task_id): $($task.title)"
        Write-Host "  Agent:        $($task.assigned_agent)"
        Write-Host "  Department:   $($task.lead_department)"
        Write-Host "  Status:       $($task.status)"
        Write-Host "  Required:     $($task.required)"

        if (@($task.dependencies).Count -gt 0) {
            Write-Host (
                "  Depends on:   {0}" -f
                (@($task.dependencies) -join ", ")
            )
        }
        else {
            Write-Host "  Depends on:   None"
        }
    }
}
