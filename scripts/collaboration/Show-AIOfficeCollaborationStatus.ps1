param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$index = & ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE AGENT COLLABORATION STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host (
    "Agents: " +
    [string]$index.agent_count +
    " total | " +
    [string]$index.available_agent_count +
    " available"
)
Write-Host (
    "Messages: " +
    [string]$index.message_count
)
Write-Host (
    "Delegations: " +
    [string]$index.open_delegation_count +
    " open"
)
Write-Host (
    "Conflicts: " +
    [string]$index.open_conflict_count +
    " open"
)
Write-Host ""

foreach ($agent in @($index.agents)) {
    Write-Host (
        [string]$agent.agent_id +
        " | " +
        [string]$agent.department +
        " | " +
        [string]$agent.role +
        " | " +
        [string]$agent.status
    )
}

Write-Host ""
return $index
