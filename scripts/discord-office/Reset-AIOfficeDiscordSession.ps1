param(
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [Parameter(Mandatory=$true)][string]$DiscordGuildId,
    [Parameter(Mandatory=$true)][string]$DiscordChannelId,
    [string]$Title = "Discord Conversation"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$Current = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordSessionMapping.ps1" `
    -DiscordUserId $DiscordUserId `
    -DiscordChannelId $DiscordChannelId

if ($null -ne $Current) {
    $MapPath = "E:\AI\AI-Office\workspace\discord-office\session-maps\$($Current.mapping_id).json"
    $Current.status = "completed"
    $Current.updated_at = (Get-Date).ToString("o")
    Write-AIOfficeDiscordJson -Value $Current -Path $MapPath
}

$Conversation = & "E:\AI\AI-Office\scripts\conversational-office\New-AIOfficeConversationSession.ps1" `
    -Title $Title

$Mapping = & "E:\AI\AI-Office\scripts\discord-office\New-AIOfficeDiscordSessionMapping.ps1" `
    -DiscordUserId $DiscordUserId `
    -DiscordGuildId $DiscordGuildId `
    -DiscordChannelId $DiscordChannelId `
    -ConversationSessionId ([string]$Conversation.session_id)

Write-Host "Discord conversation reset: $($Conversation.session_id)" -ForegroundColor Green

return [pscustomobject]@{
    conversation = $Conversation
    mapping = $Mapping
}
