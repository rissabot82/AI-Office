param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Objective,
    [Parameter(Mandatory=$true)][string]$SuccessCriteriaJson,
    [string]$Owner = "chief-of-staff",
    [ValidateSet("low","normal","high","urgent","critical")]
    [string]$Priority = "normal",
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "medium",
    [ValidateSet("pending","approved","rejected","not_required")]
    [string]$ApprovalStatus = "pending"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

try {
    $SuccessCriteria = @($SuccessCriteriaJson | ConvertFrom-Json)
}
catch {
    throw "SuccessCriteriaJson is invalid: $($_.Exception.Message)"
}

if ($SuccessCriteria.Count -lt 1) {
    throw "At least one success criterion is required."
}

if ($RiskLevel -in @("low","medium") -and $ApprovalStatus -eq "pending") {
    $ApprovalStatus = "not_required"
}

$GoalId = New-AIOfficeAutonomousGoalId
$Now = (Get-Date).ToString("o")

$Goal = [ordered]@{
    goal_id = $GoalId
    title = $Title
    objective = $Objective
    success_criteria = $SuccessCriteria
    owner = $Owner
    priority = $Priority
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = "draft"
    created_at = $Now
    updated_at = $Now
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Owner
            details = "Autonomous goal created."
        }
    )
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Goal `
    -Path ".\workspace\autonomous-workflows\goals\$GoalId.json"

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host "Autonomous goal created: $GoalId" -ForegroundColor Green
return [pscustomobject]$Goal
