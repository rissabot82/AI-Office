param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Index = & ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1"

$Delegations = @(
    & ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1" `
        -IncludeCompleted
)

$Plans = @(
    & ".\scripts\chief-of-staff\Search-AIOfficeChiefOfStaffPlans.ps1"
)

$Report = [ordered]@{
    report_id = (
        "COS-REPORT-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    generated_at = (Get-Date).ToString("o")
    status = [string]$Index.status
    inbox_count = [int]$Index.inbox_count
    open_plan_count = [int]$Index.open_plan_count
    pending_approval_count = [int]$Index.pending_approval_count
    active_delegation_count = [int]$Index.active_delegation_count
    decision_count = [int]$Index.decision_count
    plan_count = $Plans.Count
    delegation_count = $Delegations.Count
    stale_delegation_count = @(
        $Delegations | Where-Object { $_.stale -eq $true }
    ).Count
    escalation_count = @(
        $Delegations | Where-Object { $_.escalate -eq $true }
    ).Count
    plans = $Plans
    delegations = $Delegations
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\reports" `
    ([string]$Report.report_id + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Report -Path $Path

Write-Host (
    "Chief of Staff executive report created: " +
    [string]$Report.report_id
) -ForegroundColor Green

return [pscustomobject]$Report
