param(
    [Parameter(Mandatory=$true)][string]$Topic,
    [Parameter(Mandatory=$true)][string]$ParticipantIdsJson,
    [Parameter(Mandatory=$true)][string]$VotesJson,
    [double]$Threshold = 0.67
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"
. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeCollaboration.Common.ps1"

try {
    $ParticipantIds = @((ConvertFrom-Json -InputObject $ParticipantIdsJson) | ForEach-Object { $_ })
    $Votes = @((ConvertFrom-Json -InputObject $VotesJson) | ForEach-Object { $_ })
}
catch {
    throw "ParticipantIdsJson or VotesJson is invalid JSON."
}

if ($ParticipantIds.Count -lt 2) {
    throw "Consensus requires at least two participants."
}

if ($Votes.Count -ne $ParticipantIds.Count) {
    throw "Vote count must match participant count."
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

$ApproveCount = @($Votes | Where-Object { [string]$_ -eq "approve" }).Count
$Ratio = if ($Votes.Count -gt 0) { $ApproveCount / [double]$Votes.Count } else { 0.0 }
$Status = if ($Ratio -ge $Threshold) { "consensus_reached" } else { "no_consensus" }

$ConsensusId = New-AIOfficeConsensusId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    consensus_id = $ConsensusId
    topic = $Topic
    participants = @($Participants | ForEach-Object { $_ })
    votes = @($Votes | ForEach-Object { $_ })
    threshold = $Threshold
    approval_ratio = [math]::Round($Ratio,4)
    status = $Status
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeCollaborationJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\multi-agent\consensus\$ConsensusId.json"

Write-Host "Agent consensus recorded: $ConsensusId | $Status | ratio=$($Record.approval_ratio)" -ForegroundColor Green
return [pscustomobject]$Record
