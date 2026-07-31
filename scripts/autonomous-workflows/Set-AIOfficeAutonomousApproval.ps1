param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$StepId,
    [ValidateSet("approved","rejected")]
    [string]$Status,
    [Parameter(Mandatory=$true)][string]$Decision,
    [string]$CreatedBy = "Clarissa Schmidtberger"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Run = Get-AIOfficeAutonomousRun -RunId $RunId
$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId ([string]$Run.autonomous_plan_id)

$Step = @(
    $Plan.steps |
        Where-Object { [string]$_.step_id -eq $StepId }
) | Select-Object -First 1

if ($null -eq $Step) {
    throw "Workflow step not found: $StepId"
}

$ApprovalId = New-AIOfficeAutonomousApprovalId
$Now = (Get-Date).ToString("o")

$Approval = [ordered]@{
    approval_id = $ApprovalId
    run_id = $RunId
    step_id = $StepId
    status = $Status
    decision = $Decision
    created_at = $Now
    created_by = $CreatedBy
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Approval `
    -Path ".\workspace\autonomous-workflows\approvals\$ApprovalId.json"

$Step.status = if ($Status -eq "approved") { "pending" } else { "rejected" }

if ($null -eq $Step.PSObject.Properties["approval_status"]) {
    $Step | Add-Member `
        -MemberType NoteProperty `
        -Name approval_status `
        -Value $Status
}
else {
    $Step.approval_status = $Status
}

$Plan.updated_at = $Now
Save-AIOfficeAutonomousPlan -Plan $Plan

$Run.status = if ($Status -eq "approved") { "running" } else { "failed" }
$Run.updated_at = $Now
Save-AIOfficeAutonomousRun -Run $Run

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host (
    "Autonomous workflow approval recorded: " +
    $ApprovalId +
    " | " +
    $Status
) -ForegroundColor Green

return [pscustomobject]$Approval
