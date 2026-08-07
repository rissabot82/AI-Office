param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.6 Part B Collaboration Runtime..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\multi-agent\collaboration-policy.json",
    ".\config\multi-agent\handoff-schema.json",
    ".\config\multi-agent\review-schema.json",
    ".\config\multi-agent\consensus-schema.json",
    ".\config\multi-agent\conflict-schema.json",
    ".\workspace\templates\multi-agent-handoff-template.json",
    ".\workspace\templates\multi-agent-review-template.json",
    ".\workspace\templates\multi-agent-consensus-template.json",
    ".\workspace\templates\multi-agent-conflict-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\multi-agent\AIOfficeCollaboration.Common.ps1",
    ".\scripts\multi-agent\New-AIOfficeAgentHandoff.ps1",
    ".\scripts\multi-agent\New-AIOfficeAgentReview.ps1",
    ".\scripts\multi-agent\New-AIOfficeAgentConsensus.ps1",
    ".\scripts\multi-agent\New-AIOfficeAgentConflict.ps1",
    ".\scripts\multi-agent\Select-AIOfficeAgentForWork.ps1",
    ".\scripts\multi-agent\Invoke-AIOfficeParallelAgentPlan.ps1",
    ".\scripts\multi-agent\Test-AIOfficeCollaborationRuntime.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$AgentIds = New-Object System.Collections.Generic.List[string]
$AssignmentIds = New-Object System.Collections.Generic.List[string]
$HandoffIds = New-Object System.Collections.Generic.List[string]
$ReviewIds = New-Object System.Collections.Generic.List[string]
$ConsensusIds = New-Object System.Collections.Generic.List[string]
$ConflictIds = New-Object System.Collections.Generic.List[string]

try {
    $Marketing = & ".\scripts\multi-agent\New-AIOfficeAgent.ps1" `
        -Name "Certification Marketing Agent B" `
        -Role "strategist" `
        -Department "marketing" `
        -CapabilitiesJson '["campaign_planning","handoff"]' `
        -PermissionsJson '["read_memory","create_plan"]'

    $Analytics = & ".\scripts\multi-agent\New-AIOfficeAgent.ps1" `
        -Name "Certification Analytics Agent B" `
        -Role "reviewer" `
        -Department "analytics" `
        -CapabilitiesJson '["measurement","review_work"]' `
        -PermissionsJson '["read_memory","review_work"]'

    $AgentIds.Add([string]$Marketing.agent_id)
    $AgentIds.Add([string]$Analytics.agent_id)

    $Handoff = & ".\scripts\multi-agent\New-AIOfficeAgentHandoff.ps1" `
        -FromAgentId ([string]$Marketing.agent_id) `
        -ToAgentId ([string]$Analytics.agent_id) `
        -Reason "Validate handoff runtime." `
        -ContextJson '{"subject":"certification"}'

    $HandoffIds.Add([string]$Handoff.handoff_id)
    Write-Host "[HANDOFF OK] $($Handoff.handoff_id)" -ForegroundColor Green

    $Review = & ".\scripts\multi-agent\New-AIOfficeAgentReview.ps1" `
        -ReviewerAgentId ([string]$Analytics.agent_id) `
        -SubjectType "handoff" `
        -SubjectRef ([string]$Handoff.handoff_id) `
        -Verdict "approved" `
        -Score 95 `
        -Comments "Certification review passed."

    $ReviewIds.Add([string]$Review.review_id)
    Write-Host "[REVIEW OK] $($Review.review_id)" -ForegroundColor Green

    $ParticipantIdsJson = @(
        [string]$Marketing.agent_id,
        [string]$Analytics.agent_id
    ) | ConvertTo-Json -Compress

    $Consensus = & ".\scripts\multi-agent\New-AIOfficeAgentConsensus.ps1" `
        -Topic "Certification collaboration decision" `
        -ParticipantIdsJson $ParticipantIdsJson `
        -VotesJson '["approve","approve"]' `
        -Threshold 0.67

    $ConsensusIds.Add([string]$Consensus.consensus_id)

    if ([string]$Consensus.status -ne "consensus_reached") {
        throw "Consensus runtime did not reach expected result."
    }

    Write-Host "[CONSENSUS OK] $($Consensus.consensus_id)" -ForegroundColor Green

    $Conflict = & ".\scripts\multi-agent\New-AIOfficeAgentConflict.ps1" `
        -Title "Certification conflict" `
        -ParticipantIdsJson $ParticipantIdsJson `
        -Resolution "Resolved by test policy."

    $ConflictIds.Add([string]$Conflict.conflict_id)

    if ([string]$Conflict.status -ne "resolved") {
        throw "Conflict runtime did not resolve expected result."
    }

    Write-Host "[CONFLICT OK] $($Conflict.conflict_id)" -ForegroundColor Green

    $Selected = & ".\scripts\multi-agent\Select-AIOfficeAgentForWork.ps1" `
        -Department "marketing" `
        -RequiredCapability "campaign_planning"

    if ([string]$Selected.agent_id -ne [string]$Marketing.agent_id) {
        throw "Workload router did not select expected certification agent."
    }

    Write-Host "[ROUTING OK] $($Selected.agent_id)" -ForegroundColor Green

    $PlanDefinitions = @(
        [ordered]@{
            department = "marketing"
            required_capability = "campaign_planning"
            work_type = "campaign_plan"
            work_ref = "CERT-PAR-001"
            priority = "normal"
            instructions = "Create certification marketing work."
        },
        [ordered]@{
            department = "analytics"
            required_capability = "measurement"
            work_type = "measurement_review"
            work_ref = "CERT-PAR-002"
            priority = "normal"
            instructions = "Create certification analytics work."
        }
    ) | ConvertTo-Json -Depth 20 -Compress

    $Parallel = @(
        & ".\scripts\multi-agent\Invoke-AIOfficeParallelAgentPlan.ps1" `
            -AssignmentsJson $PlanDefinitions
    )

    foreach ($Assignment in $Parallel) {
        $AssignmentIds.Add([string]$Assignment.assignment_id)
    }

    if ($Parallel.Count -ne 2) {
        throw "Parallel runtime did not create two certification assignments."
    }

    Write-Host "[PARALLEL OK] 2 assignments created." -ForegroundColor Green
}
catch {
    Write-Host "[COLLAB ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Id in $AssignmentIds) {
    $Path = ".\workspace\multi-agent\assignments\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

foreach ($Id in $HandoffIds) {
    $Path = ".\workspace\multi-agent\handoffs\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

foreach ($Id in $ReviewIds) {
    $Path = ".\workspace\multi-agent\reviews\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

foreach ($Id in $ConsensusIds) {
    $Path = ".\workspace\multi-agent\consensus\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

foreach ($Id in $ConflictIds) {
    $Path = ".\workspace\multi-agent\conflicts\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

foreach ($Id in $AgentIds) {
    $Path = ".\workspace\multi-agent\agents\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

& ".\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Collaboration Runtime error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.6 Part B Collaboration Runtime checks passed." -ForegroundColor Green
