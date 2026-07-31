param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [ValidateSet("approved","rejected","pending","not_required")]
    [string]$Status,
    [Parameter(Mandatory=$true)][string]$Decision,
    [Parameter(Mandatory=$true)][string]$Reason,
    [string]$CreatedBy = "Clarissa Schmidtberger"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$ApprovalId = New-AIOfficeChiefOfStaffApprovalId
$Now = (Get-Date).ToString("o")

$Approval = [ordered]@{
    approval_id = $ApprovalId
    plan_id = $PlanId
    status = $Status
    decision = $Decision
    reason = $Reason
    created_at = $Now
    created_by = $CreatedBy
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\approvals" `
    ($ApprovalId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Approval -Path $Path

$Plan.approval_status = $Status
$Plan.updated_at = $Now

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Plan.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "approval_updated"
    actor = $CreatedBy
    details = (
        "Approval status set to " +
        $Status +
        "."
    )
})

$Plan.history = @($History | ForEach-Object { $_ })

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path ".\workspace\chief-of-staff\plans\$PlanId.json"

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host (
    "Plan approval updated: " +
    $PlanId +
    " -> " +
    $Status
) -ForegroundColor Green

return [pscustomobject]$Approval
