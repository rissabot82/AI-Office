param([Parameter(Mandatory=$true)][string]$SessionId,[ValidateSet("user","assistant","system","tool")][string]$Role,[Parameter(Mandatory=$true)][string]$Content,[string]$MetadataJson="{}")
$ErrorActionPreference="Stop"
. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"
$SessionPath="E:\AI\AI-Office\workspace\conversational-office\sessions\$SessionId.json"
if (-not (Test-Path -LiteralPath $SessionPath -PathType Leaf)) { throw "Conversation session not found: $SessionId" }
try { $Metadata=ConvertFrom-Json -InputObject $MetadataJson } catch { throw "MetadataJson is invalid JSON." }
$Id=New-AIOfficeConversationId -Prefix "MSG"
$Message=[ordered]@{message_id=$Id;session_id=$SessionId;role=$Role;content=$Content;metadata=$Metadata;created_at=(Get-Date).ToString("o")}
Write-AIOfficeConversationJson -Value $Message -Path "E:\AI\AI-Office\workspace\conversational-office\messages\$Id.json"
$Session=Get-Content -LiteralPath $SessionPath -Raw | ConvertFrom-Json
$Session.updated_at=(Get-Date).ToString("o")
Write-AIOfficeConversationJson -Value $Session -Path $SessionPath
& "E:\AI\AI-Office\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1" | Out-Null
Write-Host "Conversation message created: $Id | $Role" -ForegroundColor Green
return [pscustomobject]$Message
