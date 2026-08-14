param(
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [Parameter(Mandatory=$true)][string]$DiscordGuildId,
    [Parameter(Mandatory=$true)][string]$DiscordChannelId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$Policy = Get-AIOfficeDiscordPolicy

$UserAllowed = Test-AIOfficeDiscordIdentifierAllowed `
    -Identifier $DiscordUserId `
    -Collection "users"

$GuildAllowed = Test-AIOfficeDiscordIdentifierAllowed `
    -Identifier $DiscordGuildId `
    -Collection "guilds"

$ChannelAllowed = Test-AIOfficeDiscordIdentifierAllowed `
    -Identifier $DiscordChannelId `
    -Collection "channels"

$Authorized = $UserAllowed -and $GuildAllowed -and $ChannelAllowed

return [pscustomobject]@{
    authorized = $Authorized
    user_allowed = $UserAllowed
    guild_allowed = $GuildAllowed
    channel_allowed = $ChannelAllowed
    default_deny = [bool]$Policy.security.default_deny
}
