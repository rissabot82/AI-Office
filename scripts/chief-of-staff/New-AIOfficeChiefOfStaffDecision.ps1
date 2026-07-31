param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [Parameter(Mandatory=$true)][string]$Decision,
    [Parameter(Mandatory=$true)][string]$Reason,
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "medium",
    [string]$CreatedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$PlanPath = Join-Path `
    ".\workspace\chief-of-staff\plans" `
    ($PlanId + ".json")

if (-not (Test-Path -LiteralPath $PlanPath -PathType Leaf)) {
    throw "Plan not found: $PlanId"
}

$DecisionId = New-AIOfficeChiefOfStaffDecisionId
$ApprovalRequired = Test-AIOfficeChiefOfStaffApprovalRequired `
    -RiskLevel $RiskLevel

$Record = [ordered]@{
    decision_id = $DecisionId
    plan_id = $PlanId
    decision = $Decision
    reason = $Reason
    risk_level = $RiskLevel
    approval_required = $ApprovalRequired
    created_at = (Get-Date).ToString("o")
    created_by = $CreatedBy
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\decisions" `
    ($DecisionId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host "Chief of Staff decision recorded: $DecisionId" `
    -ForegroundColor Green

return [pscustomobject]$Record
