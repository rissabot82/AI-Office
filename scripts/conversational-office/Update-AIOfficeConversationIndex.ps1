param()
$ErrorActionPreference="Stop"
. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"
$Sessions=Get-AIOfficeConversationCollection -Directory "E:\AI\AI-Office\workspace\conversational-office\sessions" -Filter "CONV-*.json"
$Messages=Get-AIOfficeConversationCollection -Directory "E:\AI\AI-Office\workspace\conversational-office\messages" -Filter "MSG-*.json"
$Turns=Get-AIOfficeConversationCollection -Directory "E:\AI\AI-Office\workspace\conversational-office\turns" -Filter "TURN-*.json"
$Index=[ordered]@{session_count=@($Sessions).Count;message_count=@($Messages).Count;turn_count=@($Turns).Count;active_session_count=@($Sessions|Where-Object{[string]$_.status-eq"active"}).Count;updated_at=(Get-Date).ToString("o")}
Write-AIOfficeConversationJson -Value $Index -Path "E:\AI\AI-Office\workspace\conversational-office\indexes\conversation-index.json"
Write-Host "Conversation index updated: $($Index.session_count) sessions | $($Index.message_count) messages | $($Index.turn_count) turns" -ForegroundColor Green
return [pscustomobject]$Index
