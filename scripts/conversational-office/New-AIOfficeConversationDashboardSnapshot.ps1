param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\conversational-office\AIOfficeConversation.Common.ps1"

$IndexPath = "E:\AI\AI-Office\workspace\conversational-office\indexes\conversation-index.json"

& "E:\AI\AI-Office\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1" | Out-Null
$Index = Get-Content -LiteralPath $IndexPath -Raw | ConvertFrom-Json

$Sessions = Get-AIOfficeConversationCollection `
    -Directory "E:\AI\AI-Office\workspace\conversational-office\sessions" `
    -Filter "CONV-*.json"

$Messages = Get-AIOfficeConversationCollection `
    -Directory "E:\AI\AI-Office\workspace\conversational-office\messages" `
    -Filter "MSG-*.json"

$Turns = Get-AIOfficeConversationCollection `
    -Directory "E:\AI\AI-Office\workspace\conversational-office\turns" `
    -Filter "TURN-*.json"

$RecentSessions = @(
    $Sessions |
    Sort-Object { [string]$_.updated_at } -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        $SessionId = [string]$_.session_id
        $SessionMessages = @($Messages | Where-Object { [string]$_.session_id -eq $SessionId })
        $SessionTurns = @($Turns | Where-Object { [string]$_.session_id -eq $SessionId })

        [ordered]@{
            session_id = $SessionId
            title = [string]$_.title
            status = [string]$_.status
            message_count = $SessionMessages.Count
            turn_count = $SessionTurns.Count
            updated_at = [string]$_.updated_at
        }
    }
)

$CompletedTurns = @($Turns | Where-Object { [string]$_.status -eq "completed" }).Count
$FailedTurns = @($Turns | Where-Object { [string]$_.status -eq "failed" }).Count

$Snapshot = [ordered]@{
    version = "2.3.0"
    release_name = "Conversational AI Office"
    generated_at = (Get-Date).ToString("o")
    status = "operational"
    metrics = [ordered]@{
        sessions = [int]$Index.session_count
        active_sessions = [int]$Index.active_session_count
        messages = [int]$Index.message_count
        turns = [int]$Index.turn_count
        completed_turns = $CompletedTurns
        failed_turns = $FailedTurns
    }
    recent_sessions = $RecentSessions
}

$Output = "E:\AI\AI-Office\dashboard\public\data\conversational-office.json"
Write-AIOfficeConversationJson -Value $Snapshot -Path $Output

Write-Host "Conversational AI Office dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
