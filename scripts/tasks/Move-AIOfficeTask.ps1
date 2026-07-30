param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "inbox",
        "active",
        "blocked",
        "review",
        "approved",
        "outbox",
        "completed",
        "failed",
        "archived"
    )]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [string]$Details = ""
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$statusFolderMap = @{
    inbox = "inbox"
    active = "active"
    blocked = "active"
    review = "review"
    approved = "approved"
    outbox = "outbox"
    completed = "completed"
    failed = "failed"
    archived = "archive"
}

$currentTaskFolder = Get-ChildItem `
    -Path ".\workspace" `
    -Directory `
    -Recurse `
    -Filter $TaskId `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $currentTaskFolder) {
    throw "Task folder not found: $TaskId"
}

$taskJsonPath = Join-Path $currentTaskFolder.FullName "task.json"

if (-not (Test-Path -LiteralPath $taskJsonPath)) {
    throw "task.json was not found for $TaskId."
}

$task = Get-Content -LiteralPath $taskJsonPath -Raw | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$destinationParent = Join-Path ".\workspace" $statusFolderMap[$Status]
$destinationFolder = Join-Path $destinationParent $TaskId

$task.status = $Status
$task.updated_at = $timestamp
$task.workspace_location = (
    "workspace/{0}/{1}" -f $statusFolderMap[$Status], $TaskId
)

$newHistoryItem = [PSCustomObject]@{
    timestamp = $timestamp
    action = "status-changed"
    actor = "Clarissa"
    details = "Status changed to $Status. $Details".Trim()
}

$historyItems = @($task.history)
$historyItems += $newHistoryItem
$task.history = $historyItems

$task |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $taskJsonPath -Encoding UTF8

if ($currentTaskFolder.FullName -ne (
    [System.IO.Path]::GetFullPath($destinationFolder)
)) {
    if (Test-Path -LiteralPath $destinationFolder) {
        throw "Destination already exists: $destinationFolder"
    }

    Move-Item `
        -LiteralPath $currentTaskFolder.FullName `
        -Destination $destinationFolder
}

$registerPath = ".\workspace\task-register.json"
$register = Get-Content -LiteralPath $registerPath -Raw | ConvertFrom-Json

foreach ($registerTask in $register.tasks) {
    if ($registerTask.task_id -eq $TaskId) {
        $registerTask.status = $Status
        $registerTask.workspace_location = (
            "workspace/{0}/{1}" -f $statusFolderMap[$Status], $TaskId
        )
        $registerTask.updated_at = $timestamp
    }
}

$register.updated_at = $timestamp

$register |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $registerPath -Encoding UTF8

Write-Host ""
Write-Host "Task moved successfully." -ForegroundColor Green
Write-Host "Task ID: $TaskId"
Write-Host "New status: $Status"
Write-Host "New folder: $destinationFolder"
