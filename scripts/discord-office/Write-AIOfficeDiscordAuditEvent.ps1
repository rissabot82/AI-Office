param(
    [Parameter(Mandatory=$true)][string]$EventType,
    [string]$DiscordUserId = "",
    [string]$DiscordGuildId = "",
    [string]$DiscordChannelId = "",
    [string]$ConversationSessionId = "",
    [string]$Department = "",
    [string]$Outcome = "recorded",
    [string]$Details = ""
)

$ErrorActionPreference = "Stop"

$Directory = "E:\AI\AI-Office\workspace\discord-office\audit"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null

$SafeDetails = $Details

# Basic defense against accidentally persisting obvious Discord bot-token material.
$SafeDetails = $SafeDetails -replace '(?i)(bot\s+)[A-Za-z0-9_\-\.]{20,}', '$1[REDACTED]'
$SafeDetails = $SafeDetails -replace '(?i)(token["''\s:=]+)[A-Za-z0-9_\-\.]{20,}', '$1[REDACTED]'

$Id = "DCAUD-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + [guid]::NewGuid().ToString("N").Substring(0,6).ToUpperInvariant()

$Record = [ordered]@{
    audit_id = $Id
    event_type = $EventType
    discord_user_id = $DiscordUserId
    discord_guild_id = $DiscordGuildId
    discord_channel_id = $DiscordChannelId
    conversation_session_id = $ConversationSessionId
    department = $Department
    outcome = $Outcome
    details = $SafeDetails
    created_at = (Get-Date).ToString("o")
}

$Path = Join-Path $Directory "$Id.json"
$Record | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8

return [pscustomobject]$Record
