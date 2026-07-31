param(
    [Parameter(Mandatory=$true)][string]$AgentId,
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$Role,
    [string[]]$Capabilities = @(),
    [string]$ManagerAgentId = "",
    [string]$Status = "available"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if (@($policy.allowed_agent_statuses) -notcontains $Status) {
    throw "Unsupported agent status: $Status"
}

if (-not $AgentId.StartsWith("AGT-")) {
    throw "AgentId must begin with AGT-"
}

$path = Get-AIOfficeAgentPath -AgentId $AgentId

if (Test-Path -LiteralPath $path -PathType Leaf) {
    throw "Agent already exists: $AgentId"
}

$now = (Get-Date).ToString("o")

$agent = [ordered]@{
    agent_id = $AgentId
    name = $Name
    department = $Department
    role = $Role
    status = $Status
    capabilities = @($Capabilities)
    manager_agent_id = $ManagerAgentId
    created_at = $now
    updated_at = $now
}

Write-AIOfficeCollaborationJson -Value $agent -Path $path
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host "Agent created: $AgentId" -ForegroundColor Green
return [pscustomobject]$agent
