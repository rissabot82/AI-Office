param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [string]$Department = "",
    [string]$AssignedTo = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$DispatchAllowed = Test-AIOfficeChiefOfStaffDispatchAllowed `
    -RiskLevel ([string]$Plan.risk_level) `
    -ApprovalStatus ([string]$Plan.approval_status)

if (-not $DispatchAllowed) {
    throw (
        "Plan cannot be delegated until approval is granted. " +
        "Risk=" +
        [string]$Plan.risk_level +
        ", approval=" +
        [string]$Plan.approval_status
    )
}

$Package = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffWorkPackage.ps1" `
    -PlanId $PlanId `
    -Department $Department

if ([string]::IsNullOrWhiteSpace($AssignedTo)) {
    $AssignedTo = [string]$Package.department
}

$DelegationId = New-AIOfficeChiefOfStaffDelegationId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    delegation_id = $DelegationId
    plan_id = $PlanId
    department = [string]$Package.department
    assigned_to = $AssignedTo
    status = "queued"
    priority = [string]$Plan.priority
    risk_level = [string]$Plan.risk_level
    approval_status = [string]$Plan.approval_status
    created_at = $Now
    updated_at = $Now
    work_package_id = [string]$Package.work_package_id
    message_id = ""
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = "chief-of-staff"
            details = "Delegation created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\delegations" `
    ($DelegationId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host "Delegation created: $DelegationId" `
    -ForegroundColor Green

return [pscustomobject]$Record
