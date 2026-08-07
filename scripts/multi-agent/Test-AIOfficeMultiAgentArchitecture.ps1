param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.6 Part A Multi-Agent Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\multi-agent\agent-policy.json",
    ".\config\multi-agent\agent-schema.json",
    ".\config\multi-agent\assignment-schema.json",
    ".\config\multi-agent\collaboration-space-schema.json",
    ".\workspace\multi-agent\indexes\agent-index.json",
    ".\workspace\templates\multi-agent-agent-template.json",
    ".\workspace\templates\multi-agent-assignment-template.json",
    ".\workspace\templates\multi-agent-collaboration-template.json"
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
    ".\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1",
    ".\scripts\multi-agent\New-AIOfficeAgent.ps1",
    ".\scripts\multi-agent\New-AIOfficeAgentAssignment.ps1",
    ".\scripts\multi-agent\New-AIOfficeCollaborationSpace.ps1",
    ".\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1",
    ".\scripts\multi-agent\Show-AIOfficeMultiAgentStatus.ps1",
    ".\scripts\multi-agent\Test-AIOfficeMultiAgentArchitecture.ps1"
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
$CollaborationIds = New-Object System.Collections.Generic.List[string]

try {
    $MarketingAgent = & ".\scripts\multi-agent\New-AIOfficeAgent.ps1" `
        -Name "Certification Marketing Strategist" `
        -Role "strategist" `
        -Department "marketing" `
        -CapabilitiesJson '["campaign_planning","audience_strategy"]' `
        -PermissionsJson '["read_memory","create_plan"]'

    $AnalyticsAgent = & ".\scripts\multi-agent\New-AIOfficeAgent.ps1" `
        -Name "Certification Analytics Reviewer" `
        -Role "reviewer" `
        -Department "analytics" `
        -CapabilitiesJson '["measurement","validation"]' `
        -PermissionsJson '["read_memory","review_work"]'

    $AgentIds.Add([string]$MarketingAgent.agent_id)
    $AgentIds.Add([string]$AnalyticsAgent.agent_id)

    Write-Host "[AGENT OK] 2 certification agents created." -ForegroundColor Green

    $Assignment = & ".\scripts\multi-agent\New-AIOfficeAgentAssignment.ps1" `
        -AgentId ([string]$MarketingAgent.agent_id) `
        -WorkType "campaign_review" `
        -WorkRef "CERT-WORK-001" `
        -Priority "normal" `
        -Instructions "Create a certification campaign plan."

    $AssignmentIds.Add([string]$Assignment.assignment_id)

    Write-Host "[ASSIGNMENT OK] $($Assignment.assignment_id)" -ForegroundColor Green

    $ParticipantsJson = @(
        [string]$MarketingAgent.agent_id,
        [string]$AnalyticsAgent.agent_id
    ) | ConvertTo-Json -Compress

    $Collaboration = & ".\scripts\multi-agent\New-AIOfficeCollaborationSpace.ps1" `
        -Title "Certification Campaign Collaboration" `
        -ParticipantIdsJson $ParticipantsJson `
        -Objective "Validate multi-agent collaboration architecture." `
        -SharedContextJson '{"certification":true}'

    $CollaborationIds.Add([string]$Collaboration.collaboration_id)

    if (@($Collaboration.participants).Count -ne 2) {
        throw "Collaboration space did not contain both certification agents."
    }

    Write-Host "[COLLAB OK] $($Collaboration.collaboration_id)" -ForegroundColor Green

    $Index = & ".\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1"

    if (
        [int]$Index.agent_count -lt 2 -or
        [int]$Index.assignment_count -lt 1 -or
        [int]$Index.collaboration_count -lt 1
    ) {
        throw "Multi-Agent index did not contain certification records."
    }

    Write-Host "[INDEX OK] $($Index.agent_count) agents | $($Index.assignment_count) assignments | $($Index.collaboration_count) collaborations" -ForegroundColor Green
}
catch {
    Write-Host "[MULTI-AGENT ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Id in $CollaborationIds) {
    $Path = ".\workspace\multi-agent\collaborations\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Id in $AssignmentIds) {
    $Path = ".\workspace\multi-agent\assignments\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Id in $AgentIds) {
    $Path = ".\workspace\multi-agent\agents\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Multi-Agent architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.6 Part A Multi-Agent Architecture checks passed." -ForegroundColor Green
