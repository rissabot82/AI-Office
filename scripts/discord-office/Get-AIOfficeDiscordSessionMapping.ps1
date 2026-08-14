param(
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [Parameter(Mandatory=$true)][string]$DiscordChannelId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$Mappings = @(
    Get-AIOfficeDiscordCollection `
        -Directory "E:\AI\AI-Office\workspace\discord-office\session-maps" `
        -Filter "DCMAP-*.json" |
    Where-Object {
        [string]$_.discord_user_id -eq $DiscordUserId -and
        [string]$_.discord_channel_id -eq $DiscordChannelId -and
        [string]$_.status -eq "active"
    } |
    Sort-Object { [string]$_.updated_at } -Descending
)

if ($Mappings.Count -eq 0) {
    return $null
}

return $Mappings[0]
