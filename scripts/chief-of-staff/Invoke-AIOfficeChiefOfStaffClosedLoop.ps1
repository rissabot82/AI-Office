param(
    [Parameter(Mandatory=$true)][string]$DelegationId,
    [Parameter(Mandatory=$true)][string]$ResultMessageId,
    [ValidateSet(
        "approved",
        "rejected",
        "needs_revision",
        "completed",
        "partially_completed"
    )]
    [string]$Outcome = "completed",
    [Parameter(Mandatory=$true)][string]$Summary,
    [switch]$CompletePlan
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Review = & `
    ".\scripts\chief-of-staff\Review-AIOfficeChiefOfStaffResult.ps1" `
    -DelegationId $DelegationId `
    -MessageId $ResultMessageId `
    -Outcome $Outcome `
    -Summary $Summary

$DelegationRecord = Get-AIOfficeChiefOfStaffDelegation `
    -DelegationId $DelegationId

$Completion = $null

if ($CompletePlan -and
    $Outcome -in @("approved","completed","partially_completed")) {
    $Completion = & `
        ".\scripts\chief-of-staff\Complete-AIOfficeChiefOfStaffPlan.ps1" `
        -PlanId ([string]$DelegationRecord.plan_id) `
        -Summary $Summary
}

return [pscustomobject]@{
    review = $Review
    completion = $Completion
}
