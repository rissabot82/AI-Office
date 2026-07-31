param(
    [Parameter(Mandatory=$true)][string]$FromDepartment,
    [Parameter(Mandatory=$true)][string]$ToDepartment,
    [Parameter(Mandatory=$true)][string]$WorkItemId,
    [Parameter(Mandatory=$true)][string]$Objective,
    [string[]]$Deliverables = @(),
    [string[]]$RequiredCapabilities = @(),
    [string]$Priority = "normal",
    [string]$RiskLevel = "medium",
    [string]$ApprovalStatus = "not_required"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentExecution.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Payload = [ordered]@{
    parent_work_item_id = $WorkItemId
    objective = $Objective
    deliverables = $Deliverables
    required_capabilities = $RequiredCapabilities
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
    -From $FromDepartment `
    -To $ToDepartment `
    -MessageType "handoff" `
    -Priority $Priority `
    -Subject ("Department handoff from " + $FromDepartment) `
    -ConversationTopic "DEPARTMENT-HANDOFF" `
    -Queue "outbox" `
    -PayloadJson ($Payload | ConvertTo-Json -Depth 20 -Compress)

$Record = [ordered]@{
    handoff_id = (
        "HOF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    from_department = $FromDepartment
    to_department = $ToDepartment
    work_item_id = $WorkItemId
    message_id = [string]$Message.message_id
    created_at = (Get-Date).ToString("o")
    status = "dispatched"
}

$Path = Join-Path `
    ".\workspace\departments\$FromDepartment\handoffs" `
    ([string]$Record.handoff_id + ".json")

Write-AIOfficeDepartmentJson -Value $Record -Path $Path

Write-Host (
    "Department handoff created: " +
    [string]$Record.handoff_id
) -ForegroundColor Green

return [pscustomobject]$Record
