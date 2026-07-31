param(
    [Parameter(Mandatory=$true)][string]$FromAgent,
    [Parameter(Mandatory=$true)][string]$ToAgent,
    [Parameter(Mandatory=$true)][string]$Subject,
    [Parameter(Mandatory=$true)][string]$Body,
    [string]$MessageType = "information",
    [string]$CorrelationId = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if (@($policy.allowed_message_types) -notcontains $MessageType) {
    throw "Unsupported message type: $MessageType"
}

if ($null -eq (Get-AIOfficeAgent -AgentId $FromAgent)) {
    throw "Sender agent not found: $FromAgent"
}

if ($null -eq (Get-AIOfficeAgent -AgentId $ToAgent)) {
    throw "Recipient agent not found: $ToAgent"
}

$messageId = New-AIOfficeCollaborationId -Prefix "MSG"

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = $messageId
}

$record = [ordered]@{
    message_id = $messageId
    from_agent = $FromAgent
    to_agent = $ToAgent
    message_type = $MessageType
    subject = $Subject
    body = $Body
    correlation_id = $CorrelationId
    created_at = (Get-Date).ToString("o")
    status = "unread"
}

$path = Join-Path ".\workspace\collaboration\messages" ($messageId + ".json")
Write-AIOfficeCollaborationJson -Value $record -Path $path

Write-Host "Agent message sent: $messageId" -ForegroundColor Green
return [pscustomobject]$record
