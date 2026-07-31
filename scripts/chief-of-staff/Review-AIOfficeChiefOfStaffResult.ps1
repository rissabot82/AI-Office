param(
    [Parameter(Mandatory=$true)][string]$DelegationId,
    [Parameter(Mandatory=$true)][string]$MessageId,
    [ValidateSet(
        "approved",
        "rejected",
        "needs_revision",
        "completed",
        "partially_completed"
    )]
    [string]$Outcome,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$CreatedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Delegation = Get-AIOfficeChiefOfStaffDelegation `
    -DelegationId $DelegationId

$Plan = Get-AIOfficeChiefOfStaffPlan `
    -PlanId ([string]$Delegation.plan_id)

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$CriteriaResults = New-Object System.Collections.Generic.List[object]

foreach ($Criterion in @($Plan.success_criteria)) {
    $CriteriaResults.Add([ordered]@{
        criterion = [string]$Criterion
        met = ($Outcome -in @("approved","completed"))
        notes = if ($Outcome -in @("approved","completed")) {
            "Marked complete during executive review."
        }
        else {
            "Requires additional work or review."
        }
    })
}

$ReviewId = New-AIOfficeChiefOfStaffReviewId
$Now = (Get-Date).ToString("o")

$Review = [ordered]@{
    review_id = $ReviewId
    plan_id = [string]$Plan.plan_id
    delegation_id = $DelegationId
    message_id = $MessageId
    outcome = $Outcome
    summary = $Summary
    criteria_results = @($CriteriaResults | ForEach-Object { $_ })
    created_at = $Now
    created_by = $CreatedBy
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\reviews" `
    ($ReviewId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Review -Path $Path

$Delegation.status = switch ($Outcome) {
    "approved" { "completed" }
    "completed" { "completed" }
    "partially_completed" { "partially_completed" }
    "needs_revision" { "revision_required" }
    "rejected" { "rejected" }
}

$Delegation.updated_at = $Now

$DelegationHistory = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Delegation.history)) {
    $DelegationHistory.Add($Entry)
}

$DelegationHistory.Add([ordered]@{
    timestamp = $Now
    action = "reviewed"
    actor = $CreatedBy
    details = (
        "Review outcome: " +
        $Outcome +
        "."
    )
})

$Delegation.history = @(
    $DelegationHistory | ForEach-Object { $_ }
)

Write-AIOfficeChiefOfStaffJson `
    -Value $Delegation `
    -Path ".\workspace\chief-of-staff\delegations\$DelegationId.json"

Write-Host "Executive review recorded: $ReviewId" `
    -ForegroundColor Green

return [pscustomobject]$Review
