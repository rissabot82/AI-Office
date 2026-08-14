param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.3 Part B Live Conversational Runtime..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\conversational-office\runtime-policy.json",
    ".\config\conversational-office\conversation-response-schema.json",
    ".\workspace\templates\conversation-response-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\conversational-office\AIOfficeConversationRuntime.Common.ps1",
    ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1",
    ".\scripts\conversational-office\Send-AIOfficeMessage.ps1",
    ".\scripts\conversational-office\Start-AIOfficeConversation.ps1",
    ".\scripts\conversational-office\Test-AIOfficeConversationRuntime.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$SessionId = ""
$CreatedFiles = New-Object System.Collections.Generic.List[string]

try {
    $Session = & ".\scripts\conversational-office\New-AIOfficeConversationSession.ps1" `
        -Title "Runtime Certification"

    $SessionId = [string]$Session.session_id
    $CreatedFiles.Add("E:\AI\AI-Office\workspace\conversational-office\sessions\$SessionId.json")

    $Result = & ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" `
        -SessionId $SessionId `
        -Content "Reply with exactly: CONVERSATION RUNTIME OK" `
        -Sensitivity "sensitive"

    $CreatedFiles.Add("E:\AI\AI-Office\workspace\conversational-office\messages\$($Result.user_message_id).json")
    $CreatedFiles.Add("E:\AI\AI-Office\workspace\conversational-office\messages\$($Result.assistant_message_id).json")
    $CreatedFiles.Add("E:\AI\AI-Office\workspace\conversational-office\turns\$($Result.turn_id).json")

    if ([string]$Result.status -ne "completed") {
        throw "Conversation runtime did not complete."
    }

    if ([string]::IsNullOrWhiteSpace([string]$Result.response)) {
        throw "Conversation runtime returned an empty response."
    }

    if ([string]$Result.provider -ne "ollama") {
        throw "Certification conversation did not use local Ollama inference."
    }

    $Loaded = & ".\scripts\conversational-office\Get-AIOfficeConversationSession.ps1" `
        -SessionId $SessionId

    if (@($Loaded.messages).Count -ne 2) {
        throw "Conversation runtime did not persist both messages."
    }

    if (@($Loaded.turns).Count -ne 1) {
        throw "Conversation runtime did not persist the turn."
    }

    if ([string]$Loaded.turns[0].status -ne "completed") {
        throw "Persisted conversation turn is not completed."
    }

    Write-Host "[LIVE RESPONSE OK] Ollama returned a conversational response." -ForegroundColor Green
    Write-Host "[PERSISTENCE OK] User + assistant messages persisted." -ForegroundColor Green
    Write-Host "[TURN OK] Conversation turn completed." -ForegroundColor Green
    Write-Host "[SESSION OK] Conversation history retrieval passed." -ForegroundColor Green
}
catch {
    Write-Host "[RUNTIME ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}
finally {
    foreach ($File in $CreatedFiles) {
        Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue
    }

    if (-not [string]::IsNullOrWhiteSpace($SessionId)) {
        Remove-Item `
            -LiteralPath "E:\AI\AI-Office\workspace\conversational-office\sessions\$SessionId.json" `
            -Force `
            -ErrorAction SilentlyContinue
    }

    & ".\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1" | Out-Null
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Live Conversational Runtime error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.3 Part B Live Conversational Runtime checks passed." -ForegroundColor Green
