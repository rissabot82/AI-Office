param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [string]$Department = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

if ([string]::IsNullOrWhiteSpace($Department)) {
    $Route = & ".\scripts\chief-of-staff\Route-AIOfficeChiefOfStaffPlan.ps1" `
        -PlanId $PlanId

    $Department = [string]$Route.department
}

$WorkPackageId = New-AIOfficeChiefOfStaffWorkPackageId
$Now = (Get-Date).ToString("o")

$Deliverables = @($Plan.success_criteria)

$Steps = @(
    [ordered]@{
        step_number = 1
        title = "Review assigned objective"
        owner = $Department
        status = "pending"
    },
    [ordered]@{
        step_number = 2
        title = "Produce required deliverables"
        owner = $Department
        status = "pending"
    },
    [ordered]@{
        step_number = 3
        title = "Return results to Chief of Staff"
        owner = $Department
        status = "pending"
    }
)

$Package = [ordered]@{
    work_package_id = $WorkPackageId
    plan_id = $PlanId
    department = $Department
    title = [string]$Plan.title
    objective = [string]$Plan.objective
    deliverables = $Deliverables
    priority = [string]$Plan.priority
    risk_level = [string]$Plan.risk_level
    approval_status = [string]$Plan.approval_status
    status = "draft"
    created_at = $Now
    updated_at = $Now
    workflow_id = [string]$Plan.workflow_id
    conversation_id = [string]$Plan.conversation_id
    correlation_id = [string]$Plan.correlation_id
    steps = $Steps
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\work-packages" `
    ($WorkPackageId + ".json")

Write-AIOfficeChiefOfStaffJson -Value $Package -Path $Path

Write-Host "Work package created: $WorkPackageId" `
    -ForegroundColor Green

return [pscustomobject]$Package
