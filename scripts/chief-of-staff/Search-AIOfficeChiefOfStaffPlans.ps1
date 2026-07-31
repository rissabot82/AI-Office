param(
    [string]$Status = "",
    [string]$Priority = "",
    [string]$RiskLevel = "",
    [string]$ApprovalStatus = "",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\plans" `
        -Filter "PLAN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Plan = Read-AIOfficeChiefOfStaffJson -Path $File.FullName

    if ($null -eq $Plan) {
        continue
    }

    if ($Status -and [string]$Plan.status -ne $Status) {
        continue
    }

    if ($Priority -and [string]$Plan.priority -ne $Priority) {
        continue
    }

    if ($RiskLevel -and [string]$Plan.risk_level -ne $RiskLevel) {
        continue
    }

    if ($ApprovalStatus -and
        [string]$Plan.approval_status -ne $ApprovalStatus) {
        continue
    }

    $Results.Add([pscustomobject]@{
        plan_id = [string]$Plan.plan_id
        title = [string]$Plan.title
        priority = [string]$Plan.priority
        risk_level = [string]$Plan.risk_level
        approval_status = [string]$Plan.approval_status
        status = [string]$Plan.status
        owner = [string]$Plan.owner
        workflow_id = [string]$Plan.workflow_id
        created_at = [string]$Plan.created_at
    })
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
