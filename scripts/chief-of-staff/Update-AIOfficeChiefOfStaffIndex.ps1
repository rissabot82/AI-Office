param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$PlanFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\plans" `
        -Filter "PLAN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$DecisionFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\decisions" `
        -Filter "DEC-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$DelegationFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\delegations" `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$InboxFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\inbox" `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$OpenPlans = 0
$PendingApprovals = 0

foreach ($File in $PlanFiles) {
    $Plan = Read-AIOfficeChiefOfStaffJson -Path $File.FullName

    if ($null -eq $Plan) {
        continue
    }

    if (@("completed","cancelled","archived") -notcontains [string]$Plan.status) {
        $OpenPlans++
    }

    if ([string]$Plan.approval_status -eq "pending") {
        $PendingApprovals++
    }
}

$LatestPlan = $PlanFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$LatestDecision = $DecisionFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$Index = [ordered]@{
    schema_version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    chief_of_staff_id = "COS-001"
    status = if ($OpenPlans -gt 0) { "active" } else { "ready" }
    inbox_count = [int]$InboxFiles.Count
    open_plan_count = [int]$OpenPlans
    pending_approval_count = [int]$PendingApprovals
    active_delegation_count = [int]$DelegationFiles.Count
    decision_count = [int]$DecisionFiles.Count
    latest_plan_id = if ($null -ne $LatestPlan) { $LatestPlan.BaseName } else { "" }
    latest_decision_id = if ($null -ne $LatestDecision) { $LatestDecision.BaseName } else { "" }
}

Write-AIOfficeChiefOfStaffJson `
    -Value $Index `
    -Path ".\workspace\chief-of-staff\chief-of-staff-index.json"

Write-Host (
    "Chief of Staff index updated: " +
    $OpenPlans.ToString() +
    " open plan(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
