param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentInbox.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Policy = Get-AIOfficeDepartmentInboxPolicy
$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Classification = & `
    ".\scripts\departments\Test-AIOfficeDepartmentWorkAcceptance.ps1" `
    -Department $Department `
    -MessageId $MessageId

$Title = [string]$Message.subject

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = "Department work from " + [string]$Message.from
}

$Objective = ""

foreach ($PropertyName in @(
    "objective",
    "instruction",
    "request",
    "summary",
    "message"
)) {
    if ($null -ne $Message.payload.PSObject.Properties[$PropertyName] -and
        -not [string]::IsNullOrWhiteSpace([string]$Message.payload.$PropertyName)) {
        $Objective = [string]$Message.payload.$PropertyName
        break
    }
}

if ([string]::IsNullOrWhiteSpace($Objective)) {
    $Objective = "Complete department work from message " + $MessageId + "."
}

$Deliverables = @()

if ($null -ne $Message.payload.PSObject.Properties["deliverables"]) {
    $Deliverables = @($Message.payload.deliverables)
}
elseif ($null -ne $Message.payload.PSObject.Properties["success_criteria"]) {
    $Deliverables = @($Message.payload.success_criteria)
}

if ($Deliverables.Count -lt 1) {
    $Deliverables = @(
        "Review the assigned request",
        "Produce the required output",
        "Return a result to the Chief of Staff"
    )
}

$RiskLevel = "medium"
$ApprovalStatus = "not_required"

if ($null -ne $Message.payload.PSObject.Properties["risk_level"]) {
    $RiskLevel = [string]$Message.payload.risk_level
}

if ($null -ne $Message.payload.PSObject.Properties["approval_status"]) {
    $ApprovalStatus = [string]$Message.payload.approval_status
}

$Now = (Get-Date).ToString("o")
$WorkItemId = New-AIOfficeDepartmentWorkItemId

$WorkItem = [ordered]@{
    work_item_id = $WorkItemId
    department = $Department
    source_message_id = $MessageId
    title = $Title
    objective = $Objective
    deliverables = $Deliverables
    priority = [string]$Message.priority
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = if ([bool]$Classification.accepted) { "queued" } else { "capability_review" }
    workflow_id = [string]$Message.workflow_id
    conversation_id = [string]$Message.conversation_id
    correlation_id = [string]$Message.correlation_id
    created_at = $Now
    updated_at = $Now
    matched_capabilities = @($Classification.matched_capabilities)
    missing_capabilities = @($Classification.missing_capabilities)
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department work item created from Message Bus intake."
        }
    )
}

$Path = Join-Path `
    ".\workspace\departments\$Department\work" `
    ($WorkItemId + ".json")

Write-AIOfficeDepartmentJson -Value $WorkItem -Path $Path

Write-Host "Department work item created: $WorkItemId" `
    -ForegroundColor Green

return [pscustomobject]$WorkItem
