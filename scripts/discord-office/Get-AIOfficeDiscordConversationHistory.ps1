param(
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [Parameter(Mandatory=$true)][string]$DiscordChannelId,
    [int]$Count = 8
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\discord-office\command-policy.json" `
    -Raw |
    ConvertFrom-Json

if ($Count -lt 1) { $Count = [int]$Policy.history.default_messages }
if ($Count -gt [int]$Policy.history.maximum_messages) {
    $Count = [int]$Policy.history.maximum_messages
}

$Mapping = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordSessionMapping.ps1" `
    -DiscordUserId $DiscordUserId `
    -DiscordChannelId $DiscordChannelId

if ($null -eq $Mapping) {
    return [pscustomobject]@{
        conversation_session_id = ""
        messages = @()
    }
}

$Loaded = & "E:\AI\AI-Office\scripts\conversational-office\Get-AIOfficeConversationSession.ps1" `
    -SessionId ([string]$Mapping.conversation_session_id)

$Messages = @(
    $Loaded.messages |
    Sort-Object { [string]$_.created_at } |
    Select-Object -Last $Count
)

return [pscustomobject]@{
    conversation_session_id = [string]$Mapping.conversation_session_id
    messages = $Messages
}
