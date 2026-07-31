param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Objective,
    [Parameter(Mandatory=$true)][string]$SuccessCriteriaJson,
    [ValidateSet("low","normal","high","urgent","critical")]
    [string]$Priority = "normal",
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "medium",
    [ValidateSet("pending","approved","rejected","not_required")]
    [string]$ApprovalStatus = "pending",
    [string]$WorkflowId = "",
    [string]$ConversationId = "",
    [string]$CorrelationId = "",
    [string]$Owner = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

try {
    $SuccessCriteria = @(
        $SuccessCriteriaJson | ConvertFrom-Json
    )
}
catch {
    throw "SuccessCriteriaJson is invalid: $($_.Exception.Message)"
}

if ($SuccessCriteria.Count -lt 1) {
    throw "At least one success criterion is required."
}

$ApprovalRequired = Test-AIOfficeChiefOfStaffApprovalRequired `
    -RiskLevel $RiskLevel

if (-not $ApprovalRequired -and $ApprovalStatus -eq "pending") {
    $ApprovalStatus = "not_required"
}

$Now = (Get-Date).ToString("o")
$PlanId = New-AIOfficeChiefOfStaffPlanId

$Plan = [ordered]@{
    plan_id = $PlanId
    title = $Title
    objective = $Objective
    success_criteria = $SuccessCriteria
    priority = $Priority
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = "draft"
    created_at = $Now
    updated_at = $Now
    owner = $Owner
    workflow_id = $WorkflowId
    conversation_id = $ConversationId
    correlation_id = $CorrelationId
    steps = @()
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Owner
            details = "Chief of Staff plan created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\plans" `
    ($PlanId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Plan -Path $Path

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host "Chief of Staff plan created: $PlanId" -ForegroundColor Green
return [pscustomobject]$Plan
