param(
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [string]$DiscordGuildId = "",
    [Parameter(Mandatory=$true)][string]$DiscordChannelId,
    [Parameter(Mandatory=$true)][string]$ConversationSessionId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$ConversationPath = "E:\AI\AI-Office\workspace\conversational-office\sessions\$ConversationSessionId.json"

if (-not (Test-Path -LiteralPath $ConversationPath -PathType Leaf)) {
    throw "Conversation session not found: $ConversationSessionId"
}

$Existing = @(
    Get-AIOfficeDiscordCollection `
        -Directory "E:\AI\AI-Office\workspace\discord-office\session-maps" `
        -Filter "DCMAP-*.json" |
    Where-Object {
        [string]$_.discord_user_id -eq $DiscordUserId -and
        [string]$_.discord_channel_id -eq $DiscordChannelId -and
        [string]$_.status -eq "active"
    }
)

foreach ($Map in $Existing) {
    $ExistingPath = "E:\AI\AI-Office\workspace\discord-office\session-maps\$($Map.mapping_id).json"
    $Map.status = "replaced"
    $Map.updated_at = (Get-Date).ToString("o")
    Write-AIOfficeDiscordJson -Value $Map -Path $ExistingPath
}

$Id = New-AIOfficeDiscordId -Prefix "DCMAP"
$Now = (Get-Date).ToString("o")

$Mapping = [ordered]@{
    mapping_id = $Id
    discord_user_id = $DiscordUserId
    discord_guild_id = $DiscordGuildId
    discord_channel_id = $DiscordChannelId
    conversation_session_id = $ConversationSessionId
    status = "active"
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeDiscordJson `
    -Value $Mapping `
    -Path "E:\AI\AI-Office\workspace\discord-office\session-maps\$Id.json"

& "E:\AI\AI-Office\scripts\discord-office\Update-AIOfficeDiscordIndex.ps1" | Out-Null

Write-Host "Discord session mapping created: $Id -> $ConversationSessionId" -ForegroundColor Green
return [pscustomobject]$Mapping
