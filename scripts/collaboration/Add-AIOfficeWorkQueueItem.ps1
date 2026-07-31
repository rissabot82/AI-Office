param(
    [Parameter(Mandatory=$true)][string]$QueueName,
    [Parameter(Mandatory=$true)][string]$ItemType,
    [Parameter(Mandatory=$true)][string]$ReferenceId,
    [int]$Priority = 100,
    [string]$AssignedAgent = "",
    [string]$PayloadJson = "{}"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

try {
    $payload = $PayloadJson | ConvertFrom-Json
}
catch {
    throw "PayloadJson is invalid JSON: $($_.Exception.Message)"
}

$queuePath = Join-Path ".\workspace\collaboration\queues" ($QueueName + ".json")
$queue = Read-AIOfficeCollaborationJson -Path $queuePath

if ($null -eq $queue) {
    $queue = [pscustomobject]@{
        queue_name = $QueueName
        updated_at = ""
        items = @()
    }
}

$items = New-Object System.Collections.Generic.List[object]

foreach ($existing in (ConvertTo-AIOfficeCollaborationArray $queue.items)) {
    $items.Add($existing)
}

$item = [ordered]@{
    queue_item_id = "QIT-" + ([guid]::NewGuid().ToString("N").Substring(0,10)).ToUpperInvariant()
    item_type = $ItemType
    reference_id = $ReferenceId
    priority = $Priority
    assigned_agent = $AssignedAgent
    status = "queued"
    created_at = (Get-Date).ToString("o")
    payload = $payload
}

$items.Add($item)

$updatedQueue = [ordered]@{
    queue_name = $QueueName
    updated_at = (Get-Date).ToString("o")
    items = @($items | Sort-Object priority, created_at | ForEach-Object { $_ })
}

Write-AIOfficeCollaborationJson -Value $updatedQueue -Path $queuePath
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host (
    "Queue item added to " +
    $QueueName +
    ": " +
    [string]$item.queue_item_id
) -ForegroundColor Green

return [pscustomobject]$item
