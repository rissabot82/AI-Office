param(
    [Parameter(Mandatory=$true)][string]$RaisedByAgent,
    [Parameter(Mandatory=$true)][string]$Subject,
    [Parameter(Mandatory=$true)][string]$Description,
    [string[]]$InvolvedAgents = @(),
    [string]$Severity = "medium"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

if ($null -eq (Get-AIOfficeAgent -AgentId $RaisedByAgent)) {
    throw "Agent not found: $RaisedByAgent"
}

$conflictId = New-AIOfficeCollaborationId -Prefix "CNF"

$record = [ordered]@{
    conflict_id = $conflictId
    raised_by_agent = $RaisedByAgent
    involved_agents = @($InvolvedAgents)
    subject = $Subject
    description = $Description
    severity = $Severity
    status = "open"
    resolution = ""
    created_at = (Get-Date).ToString("o")
    updated_at = (Get-Date).ToString("o")
}

$path = Join-Path ".\workspace\collaboration\conflicts" ($conflictId + ".json")
Write-AIOfficeCollaborationJson -Value $record -Path $path
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host "Conflict recorded: $conflictId" -ForegroundColor Yellow
return [pscustomobject]$record
