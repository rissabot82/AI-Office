param(
    [Parameter(Mandatory=$true)][ValidateSet("inbound","outbound")][string]$Direction,
    [Parameter(Mandatory=$true)][string]$DiscordMessageId,
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [string]$DiscordGuildId = "",
    [Parameter(Mandatory=$true)][string]$DiscordChannelId,
    [string]$ConversationSessionId = "",
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$Policy = Get-AIOfficeDiscordPolicy

if ($Content.Length -gt [int]$Policy.limits.max_message_characters) {
    throw "Discord message exceeds configured AI Office intake limit."
}

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeDiscordId -Prefix "DCEVT"

$Event = [ordered]@{
    event_id = $Id
    direction = $Direction
    discord_message_id = $DiscordMessageId
    discord_user_id = $DiscordUserId
    discord_guild_id = $DiscordGuildId
    discord_channel_id = $DiscordChannelId
    conversation_session_id = $ConversationSessionId
    content = $Content
    metadata = $Metadata
    created_at = (Get-Date).ToString("o")
}

$Folder = if ($Direction -eq "inbound") { "inbound" } else { "outbound" }

Write-AIOfficeDiscordJson `
    -Value $Event `
    -Path "E:\AI\AI-Office\workspace\discord-office\events\$Folder\$Id.json"

& "E:\AI\AI-Office\scripts\discord-office\Update-AIOfficeDiscordIndex.ps1" | Out-Null

Write-Host "Discord event recorded: $Id | $Direction" -ForegroundColor Green
return [pscustomobject]$Event
