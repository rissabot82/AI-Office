param(
    [string]$WorkflowId = "",
    [string]$CreatedBy = "calendar-engine",
    [switch]$IncludeCompletedTasks
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$workflowRoot = ".\workspace\workflows"

if (-not (Test-Path -LiteralPath $workflowRoot -PathType Container)) {
    throw "Package 9 workflow folder was not found."
}

$workflowFiles = Get-ChildItem `
    -Path $workflowRoot `
    -Filter "workflow.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

if (-not [string]::IsNullOrWhiteSpace($WorkflowId)) {
    $workflowFiles = @(
        $workflowFiles | Where-Object {
            $_.Directory.Name -eq $WorkflowId
        }
    )
}

$createdCount = 0

foreach ($workflowFile in $workflowFiles) {
    $workflow = Get-Content -LiteralPath $workflowFile.FullName -Raw | ConvertFrom-Json

    foreach ($task in @($workflow.tasks)) {
        if (-not $IncludeCompletedTasks -and $task.status -eq "completed") {
            continue
        }

        $dueValue = $null

        foreach ($propertyName in @("due_at", "due_date", "deadline")) {
            if (
                $task.PSObject.Properties.Name -contains $propertyName -and
                -not [string]::IsNullOrWhiteSpace([string]$task.$propertyName)
            ) {
                $dueValue = [string]$task.$propertyName
                break
            }
        }

        if ([string]::IsNullOrWhiteSpace($dueValue)) {
            continue
        }

        $taskId = if (
            $task.PSObject.Properties.Name -contains "task_id"
        ) {
            [string]$task.task_id
        }
        else {
            [string]$task.id
        }

        $existing = & ".\scripts\calendar\Search-AIOfficeEvents.ps1" `
            -Query $taskId `
            -IncludeCompleted `
            -IncludeCancelled 2>$null |
            Out-String

        if ($existing -match [regex]::Escape($taskId)) {
            continue
        }

        $title = if (
            $task.PSObject.Properties.Name -contains "title"
        ) {
            [string]$task.title
        }
        else {
            "Workflow task $taskId"
        }

        $priority = if (
            $task.PSObject.Properties.Name -contains "priority" -and
            [string]$task.priority -in @("critical", "high", "normal", "low")
        ) {
            [string]$task.priority
        }
        else {
            "normal"
        }

        & ".\scripts\calendar\New-AIOfficeEvent.ps1" `
            -Title $title `
            -Description ("Generated from workflow {0}, task {1}." -f $workflow.workflow_id, $taskId) `
            -EventType "deadline" `
            -Priority $priority `
            -StartAt $dueValue `
            -EstimatedMinutes 30 `
            -OwnerAgent ([string]$task.owner_agent) `
            -CreatedBy $CreatedBy `
            -WorkflowId ([string]$workflow.workflow_id) `
            -TaskId $taskId `
            -Tags @("workflow-sync", $taskId) |
            Out-Null

        $createdCount++
    }
}

Write-Host "Workflow calendar sync complete: $createdCount event(s) created." -ForegroundColor Green
