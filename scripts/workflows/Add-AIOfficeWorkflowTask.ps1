param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowId,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [string]$Agent,

    [Parameter(Mandatory = $true)]
    [string]$Department,

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "low",
        "normal",
        "high",
        "urgent"
    )]
    [string]$Priority = "normal",

    [Parameter(Mandatory = $false)]
    [string[]]$DependsOn = @(),

    [Parameter(Mandatory = $false)]
    [int]$Sequence = 1,

    [Parameter(Mandatory = $false)]
    [switch]$Optional,

    [Parameter(Mandatory = $false)]
    [string]$DueDate = ""
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$workflowFolder = Join-Path ".\workspace\workflows" $WorkflowId
$workflowPath = Join-Path $workflowFolder "workflow.json"

if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
    throw "Workflow not found: $WorkflowId"
}

$newTaskScript = ".\scripts\tasks\New-AIOfficeTask.ps1"

if (-not (Test-Path -LiteralPath $newTaskScript -PathType Leaf)) {
    throw "New-AIOfficeTask.ps1 was not found."
}

$workflow = Get-Content `
    -LiteralPath $workflowPath `
    -Raw |
    ConvertFrom-Json

foreach ($dependencyId in @($DependsOn)) {
    $matchingDependency = @(
        $workflow.tasks | Where-Object {
            $_.task_id -eq $dependencyId
        }
    )

    if ($matchingDependency.Count -eq 0) {
        throw (
            "Dependency task is not registered in workflow {0}: {1}" -f
            $WorkflowId,
            $dependencyId
        )
    }
}

$beforeTaskIds = @(
    Get-ChildItem `
        -Path ".\workspace" `
        -Directory `
        -Recurse `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match "^TASK-\d{8}-\d{4}$"
    } |
    Select-Object -ExpandProperty Name
)

$taskParameters = @{
    Title = $Title
    Description = $Description
    Priority = $Priority
    Agent = $Agent
    Department = $Department
}

if (-not [string]::IsNullOrWhiteSpace($DueDate)) {
    $taskParameters.DueDate = $DueDate
}

try {
    & $newTaskScript @taskParameters
}
catch {
    throw "Task creation failed: $($_.Exception.Message)"
}

$afterTaskFolders = @(
    Get-ChildItem `
        -Path ".\workspace" `
        -Directory `
        -Recurse `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match "^TASK-\d{8}-\d{4}$"
    }
)

$newTaskFolder = @(
    $afterTaskFolders |
    Where-Object {
        $beforeTaskIds -notcontains $_.Name
    } |
    Sort-Object LastWriteTime -Descending
)[0]

if ($null -eq $newTaskFolder) {
    throw "The new task was created, but its folder could not be identified."
}

$taskId = $newTaskFolder.Name
$taskJsonPath = Join-Path $newTaskFolder.FullName "task.json"

$task = Get-Content `
    -LiteralPath $taskJsonPath `
    -Raw |
    ConvertFrom-Json

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

if ($task.PSObject.Properties.Name -notcontains "parent_workflow_id") {
    $task | Add-Member `
        -NotePropertyName "parent_workflow_id" `
        -NotePropertyValue $WorkflowId
}
else {
    $task.parent_workflow_id = $WorkflowId
}

$task.dependencies = @($DependsOn)

$historyItems = @($task.history)

$historyItems += [PSCustomObject]@{
    timestamp = $timestamp
    action = "added-to-workflow"
    actor = "chief-of-staff"
    details = "Task added to workflow $WorkflowId."
}

$task.history = $historyItems
$task.updated_at = $timestamp

$task |
    ConvertTo-Json -Depth 20 |
    Set-Content `
        -LiteralPath $taskJsonPath `
        -Encoding UTF8

$workflowTasks = @($workflow.tasks)

$workflowTasks += [PSCustomObject]@{
    task_id = $taskId
    title = $Title
    assigned_agent = $Agent
    lead_department = $Department
    required = -not $Optional.IsPresent
    sequence = $Sequence
    dependencies = @($DependsOn)
    status = [string]$task.status
}

$workflow.tasks = $workflowTasks
$workflow.updated_at = $timestamp

$workflowHistory = @($workflow.history)

$workflowHistory += [PSCustomObject]@{
    timestamp = $timestamp
    action = "task-added"
    actor = "chief-of-staff"
    details = "Task $taskId was added and assigned to $Agent."
}

$workflow.history = $workflowHistory

$workflow.progress.total_tasks = @($workflow.tasks).Count

if ($workflow.status -eq "planning") {
    $workflow.status = "ready"
}

$workflow |
    ConvertTo-Json -Depth 20 |
    Set-Content `
        -LiteralPath $workflowPath `
        -Encoding UTF8

Write-Host ""
Write-Host "Task added to workflow." -ForegroundColor Green
Write-Host ""
Write-Host "Workflow ID:  $WorkflowId"
Write-Host "Task ID:      $taskId"
Write-Host "Agent:        $Agent"
Write-Host "Department:   $Department"
Write-Host "Required:     $(-not $Optional.IsPresent)"
Write-Host "Sequence:     $Sequence"
Write-Host "Dependencies: $(@($DependsOn) -join ', ')"
