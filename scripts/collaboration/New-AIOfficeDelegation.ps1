param(
    [Parameter(Mandatory=$true)][string]$FromAgent,
    [Parameter(Mandatory=$true)][string]$ToAgent,
    [Parameter(Mandatory=$true)][string]$Title,
    [string]$Description = "",
    [int]$Priority = 100,
    [int]$Depth = 0,
    [string]$ParentDelegationId = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if ($Depth -gt [int]$policy.max_delegation_depth) {
    throw "Maximum delegation depth exceeded."
}

if ($null -eq (Get-AIOfficeAgent -AgentId $FromAgent)) {
    throw "Delegating agent not found: $FromAgent"
}

if ($null -eq (Get-AIOfficeAgent -AgentId $ToAgent)) {
    throw "Recipient agent not found: $ToAgent"
}

$delegationId = New-AIOfficeCollaborationId -Prefix "DEL"
$now = (Get-Date).ToString("o")

$record = [ordered]@{
    delegation_id = $delegationId
    from_agent = $FromAgent
    to_agent = $ToAgent
    title = $Title
    description = $Description
    status = "assigned"
    priority = $Priority
    depth = $Depth
    parent_delegation_id = $ParentDelegationId
    created_at = $now
    updated_at = $now
}

$path = Join-Path ".\workspace\collaboration\delegations" ($delegationId + ".json")
Write-AIOfficeCollaborationJson -Value $record -Path $path

& ".\scripts\collaboration\Add-AIOfficeWorkQueueItem.ps1" `
    -QueueName "delegations" `
    -ItemType "delegation" `
    -ReferenceId $delegationId `
    -Priority $Priority `
    -AssignedAgent $ToAgent `
    -PayloadJson (
        $record |
        ConvertTo-Json -Depth 10 -Compress
    ) |
    Out-Null

Write-Host "Delegation created: $delegationId" -ForegroundColor Green
return [pscustomobject]$record
