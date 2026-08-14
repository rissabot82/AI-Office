param(
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$SessionId = "",
    [string]$Title = "AI Office Conversation",
    [ValidateSet("private","sensitive","normal","public")][string]$Sensitivity = "normal"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SessionId)) {
    $Session = & "E:\AI\AI-Office\scripts\conversational-office\New-AIOfficeConversationSession.ps1" `
        -Title $Title
    $SessionId = [string]$Session.session_id
}

return & "E:\AI\AI-Office\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" `
    -SessionId $SessionId `
    -Content $Content `
    -Sensitivity $Sensitivity
