param([Parameter(Mandatory=$true)][string]$SessionId)
$ErrorActionPreference="Stop"
. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"
$Path="E:\AI\AI-Office\workspace\conversational-office\sessions\$SessionId.json"
if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Conversation session not found: $SessionId" }
$Session=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json
$Messages=@(Get-AIOfficeConversationCollection -Directory "E:\AI\AI-Office\workspace\conversational-office\messages" -Filter "MSG-*.json"|Where-Object{[string]$_.session_id-eq$SessionId}|Sort-Object{[string]$_.created_at})
$Turns=@(Get-AIOfficeConversationCollection -Directory "E:\AI\AI-Office\workspace\conversational-office\turns" -Filter "TURN-*.json"|Where-Object{[string]$_.session_id-eq$SessionId}|Sort-Object{[string]$_.created_at})
return [pscustomobject]@{session=$Session;messages=$Messages;turns=$Turns}
