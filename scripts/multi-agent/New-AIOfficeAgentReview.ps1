param(
    [Parameter(Mandatory=$true)][string]$ReviewerAgentId,
    [Parameter(Mandatory=$true)][string]$SubjectType,
    [Parameter(Mandatory=$true)][string]$SubjectRef,
    [ValidateSet("approved","changes_requested","rejected")]
    [string]$Verdict = "approved",
    [ValidateRange(0,100)]
    [int]$Score = 100,
    [string]$Comments = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"
. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeCollaboration.Common.ps1"

$Reviewer = Get-AIOfficeAgent -AgentId $ReviewerAgentId
$ReviewId = New-AIOfficeAgentReviewId

$Record = [ordered]@{
    review_id = $ReviewId
    reviewer_agent_id = $ReviewerAgentId
    reviewer_agent_name = [string]$Reviewer.name
    subject_type = $SubjectType
    subject_ref = $SubjectRef
    verdict = $Verdict
    score = $Score
    comments = $Comments
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeCollaborationJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\multi-agent\reviews\$ReviewId.json"

Write-Host "Agent review created: $ReviewId | $Verdict | score=$Score" -ForegroundColor Green
return [pscustomobject]$Record
