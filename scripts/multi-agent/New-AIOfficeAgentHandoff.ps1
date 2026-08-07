param(
    [Parameter(Mandatory=$true)][string]$FromAgentId,
    [Parameter(Mandatory=$true)][string]$ToAgentId,
    [Parameter(Mandatory=$true)][string]$Reason,
    [string]$ContextJson = "{}"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"
. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeCollaboration.Common.ps1"

if ($FromAgentId -eq $ToAgentId) {
    throw "A handoff requires two different agents."
}

$FromAgent = Get-AIOfficeAgent -AgentId $FromAgentId
$ToAgent = Get-AIOfficeAgent -AgentId $ToAgentId

try {
    $Context = ConvertFrom-Json -InputObject $ContextJson
}
catch {
    throw "ContextJson is invalid JSON."
}

$HandoffId = New-AIOfficeHandoffId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    handoff_id = $HandoffId
    from_agent_id = $FromAgentId
    from_agent_name = [string]$FromAgent.name
    to_agent_id = $ToAgentId
    to_agent_name = [string]$ToAgent.name
    status = "completed"
    reason = $Reason
    context = $Context
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeCollaborationJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\multi-agent\handoffs\$HandoffId.json"

Write-Host "Agent handoff completed: $HandoffId | $($FromAgent.name) -> $($ToAgent.name)" -ForegroundColor Green
return [pscustomobject]$Record
