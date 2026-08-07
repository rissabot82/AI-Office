param(
    [Parameter(Mandatory=$true)][string]$AgentId,
    [Parameter(Mandatory=$true)][string]$WorkType,
    [string]$WorkRef = "",
    [string]$Priority = "normal",
    [string]$Instructions = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"

$Agent = Get-AIOfficeAgent -AgentId $AgentId
$AssignmentId = New-AIOfficeAssignmentId
$Now = (Get-Date).ToString("o")

$Assignment = [ordered]@{
    assignment_id = $AssignmentId
    agent_id = $AgentId
    agent_name = [string]$Agent.name
    department = [string]$Agent.department
    work_type = $WorkType
    work_ref = $WorkRef
    status = "assigned"
    priority = $Priority
    instructions = $Instructions
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeMultiAgentJson `
    -Value $Assignment `
    -Path "E:\AI\AI-Office\workspace\multi-agent\assignments\$AssignmentId.json"

& "E:\AI\AI-Office\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1" | Out-Null

Write-Host "Agent assignment created: $AssignmentId | $($Agent.name)" -ForegroundColor Green
return [pscustomobject]$Assignment
