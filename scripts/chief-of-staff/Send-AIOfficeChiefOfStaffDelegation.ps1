param(
    [Parameter(Mandatory=$true)][string]$DelegationId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$DelegationPath = Join-Path `
    ".\workspace\chief-of-staff\delegations" `
    ($DelegationId + ".json")

$Delegation = Read-AIOfficeChiefOfStaffJson -Path $DelegationPath

if ($null -eq $Delegation) {
    throw "Delegation not found: $DelegationId"
}

$PackagePath = Join-Path `
    ".\workspace\chief-of-staff\work-packages" `
    ([string]$Delegation.work_package_id + ".json")

$Package = Read-AIOfficeChiefOfStaffJson -Path $PackagePath

if ($null -eq $Package) {
    throw "Work package not found: $($Delegation.work_package_id)"
}

$MessageType = "handoff"
$To = [string]$Delegation.assigned_to

if ([string]$Delegation.department -eq "openclaw-bridge") {
    $MessageType = "execution_request"
    $To = "bridge"
}

$Payload = [ordered]@{
    delegation_id = [string]$Delegation.delegation_id
    work_package_id = [string]$Package.work_package_id
    plan_id = [string]$Package.plan_id
    department = [string]$Package.department
    objective = [string]$Package.objective
    deliverables = @($Package.deliverables)
    steps = @($Package.steps)
    risk_level = [string]$Package.risk_level
    approval_status = [string]$Package.approval_status
    action_type = if ([string]$Delegation.department -eq "openclaw-bridge") {
        "agent_task"
    }
    else {
        "department_work"
    }
}

$Arguments = @{
    From = "chief-of-staff"
    To = $To
    MessageType = $MessageType
    Subject = [string]$Package.title
    Priority = [string]$Package.priority
    WorkflowId = [string]$Package.workflow_id
    Queue = "outbox"
    PayloadJson = ($Payload | ConvertTo-Json -Depth 30 -Compress)
}

if (-not [string]::IsNullOrWhiteSpace([string]$Package.correlation_id)) {
    $Arguments.CorrelationId = [string]$Package.correlation_id
}

if (-not [string]::IsNullOrWhiteSpace([string]$Package.conversation_id)) {
    $Arguments.ConversationId = [string]$Package.conversation_id
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" @Arguments

$Now = (Get-Date).ToString("o")
$Delegation.message_id = [string]$Message.message_id
$Delegation.status = "dispatched"
$Delegation.updated_at = $Now

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Delegation.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "dispatched"
    actor = "chief-of-staff"
    details = (
        "Delegation dispatched to " +
        $To +
        " through the Message Bus."
    )
})

$Delegation.history = @($History | ForEach-Object { $_ })

Write-AIOfficeChiefOfStaffJson `
    -Value $Delegation `
    -Path $DelegationPath

$Package.status = "dispatched"
$Package.updated_at = $Now

Write-AIOfficeChiefOfStaffJson `
    -Value $Package `
    -Path $PackagePath

$Plan = Get-AIOfficeChiefOfStaffPlan `
    -PlanId ([string]$Delegation.plan_id)

$Plan.status = "in_progress"
$Plan.updated_at = $Now

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path (
        ".\workspace\chief-of-staff\plans\" +
        [string]$Plan.plan_id +
        ".json"
    )

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host (
    "Delegation dispatched: " +
    $DelegationId +
    " | message " +
    [string]$Message.message_id
) -ForegroundColor Green

return [pscustomobject]@{
    delegation = $Delegation
    work_package = $Package
    message = $Message
}
