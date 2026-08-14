param([Parameter(Mandatory=$true)][string]$SessionId,[Parameter(Mandatory=$true)][string]$UserMessageId)
$ErrorActionPreference="Stop"
. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"
if (-not (Test-Path "E:\AI\AI-Office\workspace\conversational-office\sessions\$SessionId.json")) { throw "Conversation session not found: $SessionId" }
if (-not (Test-Path "E:\AI\AI-Office\workspace\conversational-office\messages\$UserMessageId.json")) { throw "User message not found: $UserMessageId" }
$Id=New-AIOfficeConversationId -Prefix "TURN"
$Turn=[ordered]@{turn_id=$Id;session_id=$SessionId;user_message_id=$UserMessageId;assistant_message_id="";status="pending";routing=[ordered]@{};execution=[ordered]@{};created_at=(Get-Date).ToString("o");completed_at=""}
Write-AIOfficeConversationJson -Value $Turn -Path "E:\AI\AI-Office\workspace\conversational-office\turns\$Id.json"
& "E:\AI\AI-Office\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1" | Out-Null
Write-Host "Conversation turn created: $Id" -ForegroundColor Green
return [pscustomobject]$Turn
