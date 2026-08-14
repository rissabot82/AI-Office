param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"
Write-Host "`nTesting AI Office v2.3 Part A Conversational Intake Architecture...`n" -ForegroundColor Cyan
$Errors=New-Object System.Collections.Generic.List[string]
$JsonFiles=@(
".\config\conversational-office\conversation-policy.json",
".\config\conversational-office\conversation-session-schema.json",
".\config\conversational-office\conversation-message-schema.json",
".\config\conversational-office\conversation-turn-schema.json",
".\workspace\conversational-office\indexes\conversation-index.json",
".\workspace\templates\conversation-session-template.json",
".\workspace\templates\conversation-message-template.json",
".\workspace\templates\conversation-turn-template.json")
foreach($File in $JsonFiles){try{Get-Content $File -Raw|ConvertFrom-Json|Out-Null;Write-Host "[VALID JSON] $File" -ForegroundColor Green}catch{$Errors.Add("Invalid JSON: $File")}}
$Scripts=@(
".\scripts\conversational-office\AIOfficeConversation.Common.ps1",
".\scripts\conversational-office\New-AIOfficeConversationSession.ps1",
".\scripts\conversational-office\New-AIOfficeConversationMessage.ps1",
".\scripts\conversational-office\New-AIOfficeConversationTurn.ps1",
".\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1",
".\scripts\conversational-office\Get-AIOfficeConversationSession.ps1",
".\scripts\conversational-office\Test-AIOfficeConversationArchitecture.ps1")
foreach($Script in $Scripts){if(Test-Path $Script){Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green}else{$Errors.Add("Missing script: $Script")}}
$Created=@()
try{
$Session=& ".\scripts\conversational-office\New-AIOfficeConversationSession.ps1" -Title "Certification Conversation";$Created+="E:\AI\AI-Office\workspace\conversational-office\sessions\$($Session.session_id).json"
$Message=& ".\scripts\conversational-office\New-AIOfficeConversationMessage.ps1" -SessionId $Session.session_id -Role "user" -Content "Certification message";$Created+="E:\AI\AI-Office\workspace\conversational-office\messages\$($Message.message_id).json"
$Turn=& ".\scripts\conversational-office\New-AIOfficeConversationTurn.ps1" -SessionId $Session.session_id -UserMessageId $Message.message_id;$Created+="E:\AI\AI-Office\workspace\conversational-office\turns\$($Turn.turn_id).json"
$Loaded=& ".\scripts\conversational-office\Get-AIOfficeConversationSession.ps1" -SessionId $Session.session_id
if(@($Loaded.messages).Count-ne1 -or @($Loaded.turns).Count-ne1){throw "Conversation aggregation failed."}
Write-Host "[SESSION OK] $($Session.session_id)" -ForegroundColor Green
Write-Host "[MESSAGE OK] $($Message.message_id)" -ForegroundColor Green
Write-Host "[TURN OK] $($Turn.turn_id)" -ForegroundColor Green
Write-Host "[RETRIEVAL OK] Session aggregation passed." -ForegroundColor Green
}catch{Write-Host "[CONVERSATION ERR] $($_.Exception.Message)" -ForegroundColor Red;$Errors.Add($_.Exception.Message)}
finally{foreach($File in $Created){Remove-Item $File -Force -ErrorAction SilentlyContinue};& ".\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1"|Out-Null}
if($Errors.Count-gt0){Write-Host "`n$($Errors.Count) Conversational Intake Architecture error(s) found." -ForegroundColor Red;exit 1}
Write-Host "`nAll AI Office v2.3 Part A Conversational Intake Architecture checks passed." -ForegroundColor Green
