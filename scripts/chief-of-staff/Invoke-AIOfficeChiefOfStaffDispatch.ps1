param(
    [Parameter(Mandatory=$true)][string]$PlanId
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Delegation = & `
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDelegation.ps1" `
    -PlanId $PlanId

return & `
    ".\scripts\chief-of-staff\Send-AIOfficeChiefOfStaffDelegation.ps1" `
    -DelegationId ([string]$Delegation.delegation_id)
