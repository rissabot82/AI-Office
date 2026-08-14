param([string]$Title="AI Office Conversation",[string]$Entrypoint="chief-of-staff",[string]$MetadataJson="{}")
$ErrorActionPreference="Stop"
. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"
try { $Metadata=ConvertFrom-Json -InputObject $MetadataJson } catch { throw "MetadataJson is invalid JSON." }
$Id=New-AIOfficeConversationId -Prefix "CONV"; $Now=(Get-Date).ToString("o")
$Session=[ordered]@{session_id=$Id;title=$Title;status="active";entrypoint=$Entrypoint;metadata=$Metadata;created_at=$Now;updated_at=$Now}
Write-AIOfficeConversationJson -Value $Session -Path "E:\AI\AI-Office\workspace\conversational-office\sessions\$Id.json"
& "E:\AI\AI-Office\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1" | Out-Null
Write-Host "Conversation session created: $Id | $Title" -ForegroundColor Green
return [pscustomobject]$Session
