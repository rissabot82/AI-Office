param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowId
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

function Find-TaskJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskId
    )

    $result = Get-ChildItem `
        -Path ".\workspace" `
        -Filter "task.json" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Directory.Name -eq $TaskId
        } |
        Select-Object -First 1

    return $result
}

$workflowPath = Join-Path `
    ".\workspace\workflows\$WorkflowId" `
    "workflow.json"

if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
    throw "Workflow not found: $WorkflowId"
}

$policy = Get-Content `
    -LiteralPath ".\config\workflows\workflow-policy.json" `
    -Raw |
    ConvertFrom-Json

$workflow = Get-Content `
    -LiteralPath $workflowPath `
    -Raw |
    ConvertFrom-Json

$tasks = @($workflow.tasks)
$completedCount = 0
$blockedCount = 0
$activeCount = 0
$failedCount = 0
$missingCount = 0

foreach ($workflowTask in $tasks) {
    $taskFile = Find-TaskJson -TaskId $workflowTask.task_id

    if ($null -eq $taskFile) {
        $workflowTask.status = "missing"
        $missingCount++
        continue
    }

    try {
        $task = Get-Content `
            -LiteralPath $taskFile.FullName `
            -Raw |
            ConvertFrom-Json
    }
    catch {
        $workflowTask.status = "invalid"
        $failedCount++
        continue
    }

    $taskStatus = [string]$task.status
    $workflowTask.status = $taskStatus
    $workflowTask.assigned_agent = [string]$task.assigned_agent
    $workflowTask.lead_department = [string]$task.lead_department

    if ($policy.task_status_groups.completed -contains $taskStatus) {
        $completedCount++
    }
    elseif ($policy.task_status_groups.failed -contains $taskStatus) {
        $failedCount++
    }
    elseif ($policy.task_status_groups.active -contains $taskStatus) {
        $activeCount++
    }

    $dependencyBlocked = $false

    foreach ($dependencyId in @($workflowTask.dependencies)) {
        $dependencyRecord = @(
            $tasks | Where-Object {
                $_.task_id -eq $dependencyId
            }
        )

        if ($dependencyRecord.Count -eq 0) {
            $dependencyBlocked = $true
            continue
        }

        if (
            $policy.task_status_groups.completed -notcontains
            [string]$dependencyRecord[0].status
        ) {
            $dependencyBlocked = $true
        }
    }

    if ($dependencyBlocked) {
        $blockedCount++
    }
}

$totalTasks = $tasks.Count

if ($totalTasks -gt 0) {
    $percentage = [Math]::Round(
        ($completedCount / $totalTasks) * 100,
        2
    )
}
else {
    $percentage = 0
}

$workflow.progress.total_tasks = $totalTasks
$workflow.progress.completed_tasks = $completedCount
$workflow.progress.blocked_tasks = $blockedCount
$workflow.progress.percentage = $percentage

$requiredTasks = @(
    $tasks | Where-Object {
        $_.required -eq $true
    }
)

$requiredComplete = $true

foreach ($requiredTask in $requiredTasks) {
    if (
        $policy.task_status_groups.completed -notcontains
        [string]$requiredTask.status
    ) {
        $requiredComplete = $false
    }
}

$previousStatus = [string]$workflow.status

if ($workflow.approval_status -eq "approved" -and $requiredComplete) {
    $workflow.status = "completed"
}
elseif ($failedCount -gt 0 -or $missingCount -gt 0) {
    $workflow.status = "blocked"
}
elseif (
    $blockedCount -gt 0 -and
    $activeCount -eq 0 -and
    $blockedCount -eq $totalTasks
) {
    $workflow.status = "blocked"
}
elseif ($requiredComplete -and $requiredTasks.Count -gt 0) {
    $workflow.status = "review"
}
elseif ($activeCount -gt 0 -or $completedCount -gt 0) {
    $workflow.status = "active"
}
elseif ($totalTasks -gt 0) {
    $workflow.status = "ready"
}
else {
    $workflow.status = "planning"
}

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$workflow.updated_at = $timestamp

if ($previousStatus -ne $workflow.status) {
    $historyItems = @($workflow.history)

    $historyItems += [PSCustomObject]@{
        timestamp = $timestamp
        action = "workflow-status-synced"
        actor = "workflow-engine"
        details = (
            "Workflow status changed from {0} to {1}." -f
            $previousStatus,
            $workflow.status
        )
    }

    $workflow.history = $historyItems
}

$workflow |
    ConvertTo-Json -Depth 20 |
    Set-Content `
        -LiteralPath $workflowPath `
        -Encoding UTF8

Write-Host ""
Write-Host "Workflow synchronized." -ForegroundColor Green
Write-Host ""
Write-Host "Workflow ID:       $WorkflowId"
Write-Host "Status:            $($workflow.status)"
Write-Host "Total tasks:       $totalTasks"
Write-Host "Completed tasks:   $completedCount"
Write-Host "Blocked tasks:     $blockedCount"
Write-Host "Failed tasks:      $failedCount"
Write-Host "Missing tasks:     $missingCount"
Write-Host "Progress:          $percentage%"
