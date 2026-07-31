param(
    [Parameter(Mandatory=$true)][string]$PlanId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$RoutingText = (
    [string]$Plan.title +
    " " +
    [string]$Plan.objective +
    " " +
    ((@($Plan.success_criteria) -join " "))
)

$Department = Get-AIOfficeChiefOfStaffDepartment `
    -Text $RoutingText

$Record = [ordered]@{
    routing_id = (
        "RTE-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    plan_id = $PlanId
    department = $Department
    routing_text = $RoutingText
    created_at = (Get-Date).ToString("o")
    created_by = "chief-of-staff"
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\routing" `
    ([string]$Record.routing_id + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Record -Path $Path

Write-Host (
    "Plan routed: " +
    $PlanId +
    " -> " +
    $Department
) -ForegroundColor Green

return [pscustomobject]$Record
