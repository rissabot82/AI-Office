param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowId,

    [Parameter(Mandatory = $false)]
    [string]$ApprovedBy = "Clarissa",

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [switch]$Force
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

$syncScript = ".\scripts\workflows\Sync-AIOfficeWorkflow.ps1"

& $syncScript -WorkflowId $WorkflowId

$workflow = Get-Content `
    -LiteralPath $workflowPath `
    -Raw |
    ConvertFrom-Json

$policy = Get-Content `
    -LiteralPath ".\config\workflows\workflow-policy.json" `
    -Raw |
    ConvertFrom-Json

$requiredTasks = @(
    $workflow.tasks | Where-Object {
        $_.required -eq $true
    }
)

$incompleteRequiredTasks = @(
    $requiredTasks | Where-Object {
        $policy.task_status_groups.completed -notcontains
        [string]$_.status
    }
)

if (
    $incompleteRequiredTasks.Count -gt 0 -and
    -not $Force
) {
    Write-Host ""
    Write-Host "Incomplete required tasks:" -ForegroundColor Red

    foreach ($task in $incompleteRequiredTasks) {
        Write-Host (
            "  {0} [{1}] {2}" -f
            $task.task_id,
            $task.status,
            $task.title
        )
    }

    throw "The workflow cannot be completed until all required tasks are complete."
}

if (
    $workflow.approval_required -and
    [string]::IsNullOrWhiteSpace($ApprovedBy) -and
    -not $Force
) {
    throw "ApprovedBy is required to complete this workflow."
}

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$workflow.status = "completed"

if ($workflow.approval_required) {
    $workflow.approval_status = "approved"
}

$workflow.updated_at = $timestamp

$historyItems = @($workflow.history)

$historyItems += [PSCustomObject]@{
    timestamp = $timestamp
    action = "workflow-completed"
    actor = $ApprovedBy
    details = (
        "Workflow marked complete. {0}" -f
        $Notes
    ).Trim()
}

$workflow.history = $historyItems

$workflow |
    ConvertTo-Json -Depth 20 |
    Set-Content `
        -LiteralPath $workflowPath `
        -Encoding UTF8

$reportPath = Join-Path `
    ".\workspace\workflows\$WorkflowId\reports" `
    "completion-report.md"

$taskLines = foreach ($task in @($workflow.tasks | Sort-Object sequence)) {
    "- $($task.task_id): $($task.title) — $($task.status)"
}

$reportContent = @"
# Workflow Completion Report

## Workflow

$($workflow.workflow_id)

## Title

$($workflow.title)

## Description

$($workflow.description)

## Completion Status

Completed

## Approved By

$ApprovedBy

## Completion Date

$timestamp

## Progress

$($workflow.progress.completed_tasks) of $($workflow.progress.total_tasks) tasks completed.

## Tasks

$($taskLines -join "`r`n")

## Notes

$Notes
"@

Set-Content `
    -LiteralPath $reportPath `
    -Value $reportContent `
    -Encoding UTF8

Write-Host ""
Write-Host "Workflow completed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Workflow ID: $WorkflowId"
Write-Host "Approved by: $ApprovedBy"
Write-Host "Report:      $reportPath"
