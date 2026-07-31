param(
    [Parameter(Mandatory=$true)][string]$MessageId,
    [Parameter(Mandatory=$true)][string]$RequestedBy,
    [Parameter(Mandatory=$true)][string]$ActionType,
    [Parameter(Mandatory=$true)][string]$PayloadJson,
    [string]$WorkflowId = "",
    [string]$CorrelationId = "",
    [string]$ConversationId = "",
    [ValidateSet("low","medium","high","critical")]
    [string]$RiskLevel = "high",
    [ValidateSet("pending","approved","rejected","not_required")]
    [string]$ApprovalStatus = "pending"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

try {
    $Payload = $PayloadJson | ConvertFrom-Json
}
catch {
    throw "PayloadJson is invalid: $($_.Exception.Message)"
}

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

if ($null -eq $Message) {
    throw "Message not found: $MessageId"
}

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = [string]$Message.correlation_id
}

if ([string]::IsNullOrWhiteSpace($ConversationId)) {
    $ConversationId = [string]$Message.conversation_id
}

$Now = (Get-Date).ToString("o")
$RequestId = New-AIOfficeBridgeRequestId

$Request = [ordered]@{
    bridge_request_id = $RequestId
    message_id = $MessageId
    correlation_id = $CorrelationId
    conversation_id = $ConversationId
    workflow_id = $WorkflowId
    requested_by = $RequestedBy
    target_engine = "OpenClaw"
    action_type = $ActionType
    risk_level = $RiskLevel
    approval_status = $ApprovalStatus
    status = "queued"
    created_at = $Now
    updated_at = $Now
    payload = $Payload
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $RequestedBy
            details = "Bridge request created."
        }
    )
}

$Path = Join-Path `
    ".\workspace\bridge\requests" `
    ($RequestId + ".json")

Write-AIOfficeBridgeJson -Value $Request -Path $Path

& ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
    Out-Null

Write-Host "Bridge request created: $RequestId" -ForegroundColor Green
return [pscustomobject]$Request
