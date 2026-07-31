param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$agents = New-Object System.Collections.Generic.List[object]

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\agents" `
        -Filter "AGT-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $agent = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $agent) {
        $agents.Add([ordered]@{
            agent_id = [string]$agent.agent_id
            name = [string]$agent.name
            department = [string]$agent.department
            role = [string]$agent.role
            status = [string]$agent.status
            file = $file.Name
        })
    }
}

$queues = New-Object System.Collections.Generic.List[object]

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\queues" `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "queue-index.json" }
)) {
    $queue = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $queue) {
        $items = ConvertTo-AIOfficeCollaborationArray $queue.items
        $queues.Add([ordered]@{
            queue_name = [string]$queue.queue_name
            item_count = [int]$items.Count
            queued_count = [int](@($items | Where-Object { $_.status -eq "queued" }).Count)
            file = $file.Name
        })
    }
}

$messageCount = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\messages" `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
).Count

$openDelegations = 0

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\delegations" `
        -Filter "DEL-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $record = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $record -and
        [string]$record.status -notin @("completed","rejected","cancelled")) {
        $openDelegations++
    }
}

$openConflicts = 0

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\conflicts" `
        -Filter "CNF-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $record = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $record -and [string]$record.status -eq "open") {
        $openConflicts++
    }
}

$availableCount = @(
    $agents | Where-Object { $_.status -eq "available" }
).Count

$index = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    agent_count = [int]$agents.Count
    available_agent_count = [int]$availableCount
    message_count = [int]$messageCount
    open_delegation_count = [int]$openDelegations
    open_conflict_count = [int]$openConflicts
    agents = @($agents | Sort-Object department, name | ForEach-Object { $_ })
    queues = @($queues | Sort-Object queue_name | ForEach-Object { $_ })
}

Write-AIOfficeCollaborationJson `
    -Value $index `
    -Path ".\workspace\collaboration\collaboration-index.json"

$queueIndex = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    queues = @($queues | Sort-Object queue_name | ForEach-Object { $_ })
}

Write-AIOfficeCollaborationJson `
    -Value $queueIndex `
    -Path ".\workspace\collaboration\queues\queue-index.json"

Write-Host (
    "Collaboration index updated: " +
    $agents.Count.ToString() +
    " agent(s), " +
    $openDelegations.ToString() +
    " open delegation(s)."
) -ForegroundColor Green

return [pscustomobject]$index
