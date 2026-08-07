param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$ParticipantIdsJson,
    [string]$Resolution = "",
    [switch]$EscalateToChiefOfStaff
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"
. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeCollaboration.Common.ps1"

try {
    $ParticipantIds = @((ConvertFrom-Json -InputObject $ParticipantIdsJson) | ForEach-Object { $_ })
}
catch {
    throw "ParticipantIdsJson is invalid JSON."
}

$Participants = New-Object System.Collections.Generic.List[object]

foreach ($AgentId in $ParticipantIds) {
    $Agent = Get-AIOfficeAgent -AgentId ([string]$AgentId)
    $Participants.Add([pscustomobject]@{
        agent_id = [string]$Agent.agent_id
        name = [string]$Agent.name
        department = [string]$Agent.department
    })
}

$ConflictId = New-AIOfficeConflictId
$Now = (Get-Date).ToString("o")

$Status = if ($Resolution) { "resolved" } elseif ($EscalateToChiefOfStaff) { "escalated" } else { "open" }

$Record = [ordered]@{
    conflict_id = $ConflictId
    title = $Title
    participants = @($Participants | ForEach-Object { $_ })
    status = $Status
    resolution = $Resolution
    escalated_to_chief_of_staff = [bool]$EscalateToChiefOfStaff
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeCollaborationJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\multi-agent\conflicts\$ConflictId.json"

Write-Host "Agent conflict recorded: $ConflictId | $Status" -ForegroundColor Green
return [pscustomobject]$Record
