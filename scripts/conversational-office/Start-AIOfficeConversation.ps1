param(
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
else {
    $Session = & "E:\AI\AI-Office\scripts\conversational-office\Get-AIOfficeConversationSession.ps1" `
        -SessionId $SessionId
}

Write-Host ""
Write-Host "AI OFFICE CONVERSATION" -ForegroundColor Cyan
Write-Host "Session: $SessionId" -ForegroundColor DarkGray
Write-Host "Type /exit to leave. Type /session to show the session ID." -ForegroundColor DarkGray
Write-Host ""

while ($true) {
    $InputText = Read-Host "You"

    if ([string]::IsNullOrWhiteSpace($InputText)) {
        continue
    }

    if ($InputText -eq "/exit") {
        break
    }

    if ($InputText -eq "/session") {
        Write-Host $SessionId -ForegroundColor Cyan
        continue
    }

    try {
        $Result = & "E:\AI\AI-Office\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" `
            -SessionId $SessionId `
            -Content $InputText `
            -Sensitivity $Sensitivity

        Write-Host ""
        Write-Host "AI Office" -ForegroundColor Green
        Write-Host ([string]$Result.response)
        Write-Host ""
        Write-Host ("[" + [string]$Result.provider + " | " + [string]$Result.model + "]") -ForegroundColor DarkGray
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host ("AI Office runtime error: " + $_.Exception.Message) -ForegroundColor Red
        Write-Host ""
    }
}
