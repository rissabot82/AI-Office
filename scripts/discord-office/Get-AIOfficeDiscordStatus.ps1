param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$Policy = Get-AIOfficeDiscordPolicy
$Allowlist = Get-AIOfficeDiscordAllowlist
$State = Get-Content `
    -LiteralPath "E:\AI\AI-Office\workspace\discord-office\state\runtime-state.json" `
    -Raw |
    ConvertFrom-Json

$Index = & "E:\AI\AI-Office\scripts\discord-office\Update-AIOfficeDiscordIndex.ps1"

$TokenPresent = -not [string]::IsNullOrWhiteSpace(
    [Environment]::GetEnvironmentVariable(
        [string]$Policy.security.token_environment_variable,
        "User"
    )
)

return [pscustomobject]@{
    version = "2.4.0"
    status = [string]$State.status
    connected = [bool]$State.connected
    token_configured = $TokenPresent
    allowed_guilds = @($Allowlist.guilds).Count
    allowed_channels = @($Allowlist.channels).Count
    allowed_users = @($Allowlist.users).Count
    inbound_events = [int]$Index.inbound_event_count
    outbound_events = [int]$Index.outbound_event_count
    active_session_mappings = [int]$Index.active_session_mapping_count
}
