param(
    [switch]$IncludeCompleted
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Policy = Get-AIOfficeChiefOfStaffDelegationPolicy
$Now = Get-Date
$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\delegations" `
        -Filter "DLG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Delegation = Read-AIOfficeChiefOfStaffJson -Path $File.FullName

    if ($null -eq $Delegation) {
        continue
    }

    if (-not $IncludeCompleted -and
        @("completed","cancelled","archived") -contains
        [string]$Delegation.status) {
        continue
    }

    $CreatedAt = [datetime]$Delegation.created_at
    $AgeHours = ($Now - $CreatedAt).TotalHours
    $Stale = $AgeHours -ge [double]$Policy.monitoring.stale_after_hours
    $Escalate = $AgeHours -ge [double]$Policy.monitoring.escalate_after_hours

    if ([string]$Delegation.risk_level -eq "critical") {
        $Escalate = $AgeHours -ge
            [double]$Policy.monitoring.critical_escalation_after_hours
    }

    $Results.Add([pscustomobject]@{
        delegation_id = [string]$Delegation.delegation_id
        plan_id = [string]$Delegation.plan_id
        department = [string]$Delegation.department
        assigned_to = [string]$Delegation.assigned_to
        status = [string]$Delegation.status
        priority = [string]$Delegation.priority
        risk_level = [string]$Delegation.risk_level
        message_id = [string]$Delegation.message_id
        age_hours = [math]::Round($AgeHours, 2)
        stale = $Stale
        escalate = $Escalate
    })
}

return @(
    $Results |
        Sort-Object escalate, stale, priority -Descending
)
