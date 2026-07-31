param(
    [Parameter(Mandatory=$true)][string]$ExecutionId,
    [string]$Recipient = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Policy = Get-AIOfficeBridgeResultPolicy

if ($null -eq $Policy) {
    throw "Bridge result policy could not be loaded."
}

if ([string]::IsNullOrWhiteSpace($Recipient)) {
    $Recipient = [string]$Policy.publishing.default_recipient
}

$Normalized = & ".\scripts\bridge\ConvertTo-AIOfficeNormalizedResult.ps1" `
    -ExecutionId $ExecutionId

$RequestPath = Join-Path `
    ".\workspace\bridge\requests" `
    ([string]$Normalized.bridge_request_id + ".json")

$Request = Read-AIOfficeBridgeJson -Path $RequestPath

$From = "bridge"
$CorrelationId = ""
$ConversationId = ""
$WorkflowId = ""

if ($null -ne $Request) {
    $CorrelationId = [string]$Request.correlation_id
    $ConversationId = [string]$Request.conversation_id
    $WorkflowId = [string]$Request.workflow_id
}

$MessageType = [string]$Policy.publishing.result_message_type
$Priority = "normal"
$Subject = "OpenClaw execution completed"

if ([string]$Normalized.status -eq "failed") {
    $MessageType = [string]$Policy.publishing.failure_message_type
    $Priority = "high"
    $Subject = "OpenClaw execution failed"
}

$Payload = [ordered]@{
    execution_id = [string]$Normalized.execution_id
    bridge_request_id = [string]$Normalized.bridge_request_id
    normalized_result_id = [string]$Normalized.normalized_result_id
    status = [string]$Normalized.status
    summary = [string]$Normalized.summary
    artifacts = @($Normalized.artifacts)
}

$PayloadJson = $Payload |
    ConvertTo-Json -Depth 40 -Compress

$Arguments = @{
    From = $From
    To = $Recipient
    MessageType = $MessageType
    Subject = $Subject
    Priority = $Priority
    WorkflowId = $WorkflowId
    Queue = [string]$Policy.publishing.queue
    PayloadJson = $PayloadJson
}

if (-not [string]::IsNullOrWhiteSpace($CorrelationId)) {
    $Arguments.CorrelationId = $CorrelationId
}

if (-not [string]::IsNullOrWhiteSpace($ConversationId)) {
    $Arguments.ConversationId = $ConversationId
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" @Arguments

$PublishedRecord = [ordered]@{
    published_at = (Get-Date).ToString("o")
    execution_id = [string]$Normalized.execution_id
    normalized_result_id = [string]$Normalized.normalized_result_id
    message_id = [string]$Message.message_id
    recipient = $Recipient
    message_type = $MessageType
    status = "published"
}

$PublishedPath = Join-Path `
    ".\workspace\bridge\results\published" `
    ([string]$Normalized.normalized_result_id + ".json")

Write-AIOfficeBridgeJson `
    -Value $PublishedRecord `
    -Path $PublishedPath

Write-Host (
    "Execution result published: " +
    [string]$Message.message_id
) -ForegroundColor Green

return [pscustomobject]$PublishedRecord
