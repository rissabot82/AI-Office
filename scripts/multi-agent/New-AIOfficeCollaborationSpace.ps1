param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$ParticipantIdsJson,
    [string]$Objective = "",
    [string]$SharedContextJson = "{}"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"

try {
    $ParticipantIds = @((ConvertFrom-Json -InputObject $ParticipantIdsJson) | ForEach-Object { $_ })
    $SharedContext = ConvertFrom-Json -InputObject $SharedContextJson
}
catch {
    throw "ParticipantIdsJson or SharedContextJson is invalid JSON."
}

if ($ParticipantIds.Count -lt 2) {
    throw "A collaboration space requires at least two agents."
}

$Participants = New-Object System.Collections.Generic.List[object]

foreach ($AgentId in $ParticipantIds) {
    $Agent = Get-AIOfficeAgent -AgentId ([string]$AgentId)

    $Participants.Add([pscustomobject]@{
        agent_id = [string]$Agent.agent_id
        name = [string]$Agent.name
        department = [string]$Agent.department
        role = [string]$Agent.role
    })
}

$CollaborationId = New-AIOfficeCollaborationId
$Now = (Get-Date).ToString("o")

$Collaboration = [ordered]@{
    collaboration_id = $CollaborationId
    title = $Title
    participants = @($Participants | ForEach-Object { $_ })
    status = "active"
    objective = $Objective
    shared_context = $SharedContext
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeMultiAgentJson `
    -Value $Collaboration `
    -Path "E:\AI\AI-Office\workspace\multi-agent\collaborations\$CollaborationId.json"

& "E:\AI\AI-Office\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1" | Out-Null

Write-Host "Collaboration space created: $CollaborationId | $Title" -ForegroundColor Green
return [pscustomobject]$Collaboration
