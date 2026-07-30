param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("low", "normal", "high", "urgent")]
    [string]$Priority = "normal",

    [Parameter(Mandatory = $false)]
    [string]$Agent = "chief-of-staff",

    [Parameter(Mandatory = $false)]
    [string]$Department = "executive",

    [Parameter(Mandatory = $false)]
    [string]$DueDate,

    [Parameter(Mandatory = $false)]
    [switch]$NoApproval
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$today = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$existingTaskFolders = Get-ChildItem `
    -Path ".\workspace\inbox" `
    -Directory `
    -Filter "TASK-$today-*" `
    -ErrorAction SilentlyContinue

$highestNumber = 0

foreach ($folder in $existingTaskFolders) {
    if ($folder.Name -match "^TASK-$today-(\d{4})$") {
        $number = [int]$Matches[1]

        if ($number -gt $highestNumber) {
            $highestNumber = $number
        }
    }
}

$nextNumber = $highestNumber + 1
$taskId = "TASK-$today-{0:D4}" -f $nextNumber
$taskFolder = ".\workspace\inbox\$taskId"

New-Item -ItemType Directory -Path $taskFolder -Force | Out-Null

$approvalRequired = -not $NoApproval.IsPresent

if ($approvalRequired) {
    $approvalStatus = "pending"
}
else {
    $approvalStatus = "not-required"
}

$dueDateValue = $null

if (-not [string]::IsNullOrWhiteSpace($DueDate)) {
    try {
        $dueDateValue = (
            [datetime]::Parse($DueDate)
        ).ToString("yyyy-MM-dd")
    }
    catch {
        throw "DueDate must be a valid date, such as 2026-08-15."
    }
}

$taskObject = [ordered]@{
    task_id = $taskId
    title = $Title
    description = $Description
    status = "inbox"
    priority = $Priority
    created_at = $timestamp
    updated_at = $timestamp
    created_by = "Clarissa"
    assigned_agent = $Agent
    supporting_agents = @()
    lead_department = $Department
    approval_required = $approvalRequired
    approval_status = $approvalStatus
    due_date = $dueDateValue
    workspace_location = "workspace/inbox/$taskId"
    deliverables = @()
    dependencies = @()
    tags = @()
    notes = @()
    history = @(
        [ordered]@{
            timestamp = $timestamp
            action = "created"
            actor = "Clarissa"
            details = "Task created in inbox."
        }
    )
}

$taskJson = $taskObject | ConvertTo-Json -Depth 10

Set-Content `
    -LiteralPath (Join-Path $taskFolder "task.json") `
    -Value $taskJson `
    -Encoding UTF8

$briefContent = @"
# $Title

Task ID: $taskId
Status: inbox
Priority: $Priority
Assigned Agent: $Agent
Lead Department: $Department
Created: $timestamp
Due Date: $dueDateValue
Approval Required: $approvalRequired

## Requested Outcome

$Description

## Background

Add relevant background here.

## Required Deliverables

- Add deliverables here.

## Constraints

- Add constraints here.

## Available Sources

- Add source locations here.

## Dependencies

- Add dependencies here.

## Completion Criteria

Describe how the task will be judged complete.

## Notes

Add task-specific notes here.
"@

Set-Content `
    -LiteralPath (Join-Path $taskFolder "brief.md") `
    -Value $briefContent `
    -Encoding UTF8

$registerPath = ".\workspace\task-register.json"
$register = Get-Content -LiteralPath $registerPath -Raw | ConvertFrom-Json

$registerTask = [ordered]@{
    task_id = $taskId
    title = $Title
    status = "inbox"
    priority = $Priority
    assigned_agent = $Agent
    lead_department = $Department
    due_date = $dueDateValue
    workspace_location = "workspace/inbox/$taskId"
    updated_at = $timestamp
}

$taskList = @($register.tasks)
$taskList += $registerTask

$updatedRegister = [ordered]@{
    register_version = $register.register_version
    updated_at = $timestamp
    tasks = $taskList
}

$updatedRegister |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $registerPath -Encoding UTF8

Write-Host ""
Write-Host "Task created successfully." -ForegroundColor Green
Write-Host "Task ID: $taskId"
Write-Host "Folder: $taskFolder"
Write-Host ""
Write-Host "Edit the task brief here:"
Write-Host (Join-Path $taskFolder "brief.md")
