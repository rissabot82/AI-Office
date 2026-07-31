param(
    [Parameter(Mandatory=$true)][string]$From,
    [Parameter(Mandatory=$true)][string]$To,
    [Parameter(Mandatory=$true)][string]$MessageType,
    [Parameter(Mandatory=$true)][string]$PayloadJson,
    [string]$Subject = "",
    [string]$Priority = "normal",
    [string]$WorkflowId = "",
    [string]$CorrelationId = "",
    [string]$ConversationId = "",
    [string]$ConversationTopic = "GENERAL",
    [string]$Queue = "outbox",
    [switch]$NoAcknowledgement
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Policy = Get-AIOfficeMessagingPolicy
$Identity = Get-AIOfficeMessagingIdentity

if (@($Policy.allowed_priorities) -notcontains $Priority) {
    throw "Unsupported priority: $Priority"
}

if (@($Policy.allowed_message_types) -notcontains $MessageType) {
    throw "Unsupported message type: $MessageType"
}

try {
    $Payload = $PayloadJson | ConvertFrom-Json
}
catch {
    throw "PayloadJson is invalid: $($_.Exception.Message)"
}

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = New-AIOfficeCorrelationId
}

if ([string]::IsNullOrWhiteSpace($ConversationId)) {
    $ConversationId = New-AIOfficeConversationId -Topic $ConversationTopic
}

$Now = (Get-Date).ToString("o")
$MessageId = New-AIOfficeMessageId

$Message = [ordered]@{
    message_id = $MessageId
    correlation_id = $CorrelationId
    conversation_id = $ConversationId
    office_id = [string]$Identity.office_id
    office_version = "1.1.2"
    from = $From
    to = $To
    message_type = $MessageType
    priority = $Priority
    status = "queued"
    subject = $Subject
    workflow_id = $WorkflowId
    created_at = $Now
    updated_at = $Now
    available_at = $Now
    expires_at = $null
    delivery_attempts = 0
    requires_acknowledgement = (-not $NoAcknowledgement)
    acknowledged_at = $null
    payload = $Payload
    metadata = [ordered]@{
        source = "AI Office Message Bus"
        queue = $Queue
    }
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $From
            details = "Message created in queue $Queue."
        }
    )
}

$QueuePath = Get-AIOfficeMessageQueuePath -Queue $Queue
$Path = Join-Path $QueuePath ($MessageId + ".json")

Write-AIOfficeMessagingJson -Value $Message -Path $Path

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" | Out-Null

Write-Host "Message created: $MessageId" -ForegroundColor Green
return [pscustomobject]$Message
