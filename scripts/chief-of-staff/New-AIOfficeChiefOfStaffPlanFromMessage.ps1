param(
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffInbox.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Classification = & `
    ".\scripts\chief-of-staff\Classify-AIOfficeChiefOfStaffMessage.ps1" `
    -MessageId $MessageId

$Policy = Get-AIOfficeChiefOfStaffInboxPolicy

$Title = [string]$Message.subject

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = (
        [string]$Classification.classification +
        " from " +
        [string]$Message.from
    )
}

$Objective = ""

foreach ($PropertyName in @(
    "objective",
    "request",
    "instruction",
    "summary",
    "message"
)) {
    if ($null -ne $Message.payload.PSObject.Properties[$PropertyName] -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Message.payload.$PropertyName
        )) {
        $Objective = [string]$Message.payload.$PropertyName
        break
    }
}

if ([string]::IsNullOrWhiteSpace($Objective)) {
    $Objective = (
        "Review and resolve Chief of Staff message " +
        $MessageId +
        "."
    )
}

$SuccessCriteria = @($Policy.planning.default_success_criteria)

if ($null -ne $Message.payload.PSObject.Properties["success_criteria"]) {
    $Provided = @($Message.payload.success_criteria)

    if ($Provided.Count -gt 0) {
        $SuccessCriteria = $Provided
    }
}

$ApprovalStatus = if ([bool]$Classification.approval_required) {
    "pending"
}
else {
    "not_required"
}

$Plan = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1" `
    -Title $Title `
    -Objective $Objective `
    -SuccessCriteriaJson (
        $SuccessCriteria | ConvertTo-Json -Depth 10 -Compress
    ) `
    -Priority ([string]$Classification.priority) `
    -RiskLevel ([string]$Classification.risk_level) `
    -ApprovalStatus $ApprovalStatus `
    -WorkflowId ([string]$Message.workflow_id) `
    -ConversationId ([string]$Message.conversation_id) `
    -CorrelationId ([string]$Message.correlation_id)

$PlanPath = Join-Path `
    ".\workspace\chief-of-staff\plans" `
    ([string]$Plan.plan_id + ".json")

$StoredPlan = Read-AIOfficeChiefOfStaffJson -Path $PlanPath

$StoredPlan.steps = @(
    [ordered]@{
        step_number = 1
        title = "Review request"
        owner = "chief-of-staff"
        department = "executive"
        status = "pending"
    },
    [ordered]@{
        step_number = 2
        title = "Assign responsible department"
        owner = "chief-of-staff"
        department = "executive"
        status = "pending"
    },
    [ordered]@{
        step_number = 3
        title = "Execute or delegate work"
        owner = "unassigned"
        department = "unassigned"
        status = "pending"
    },
    [ordered]@{
        step_number = 4
        title = "Report outcome"
        owner = "chief-of-staff"
        department = "executive"
        status = "pending"
    }
)

$StoredPlan.updated_at = (Get-Date).ToString("o")

Write-AIOfficeChiefOfStaffJson `
    -Value $StoredPlan `
    -Path $PlanPath

Write-Host (
    "Chief of Staff plan generated from message: " +
    [string]$Plan.plan_id
) -ForegroundColor Green

return $StoredPlan
