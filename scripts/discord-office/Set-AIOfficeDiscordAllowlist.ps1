param(
    [Parameter(Mandatory=$true)][string]$GuildId,
    [Parameter(Mandatory=$true)][string]$ChannelId,
    [Parameter(Mandatory=$true)][string]$UserId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$Path = "E:\AI\AI-Office\config\discord-office\discord-allowlist.json"
$Allowlist = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json

$Guilds = New-Object System.Collections.Generic.List[string]
$Channels = New-Object System.Collections.Generic.List[string]
$Users = New-Object System.Collections.Generic.List[string]

foreach ($Value in @($Allowlist.guilds)) { if (-not [string]::IsNullOrWhiteSpace([string]$Value)) { $Guilds.Add([string]$Value) } }
foreach ($Value in @($Allowlist.channels)) { if (-not [string]::IsNullOrWhiteSpace([string]$Value)) { $Channels.Add([string]$Value) } }
foreach ($Value in @($Allowlist.users)) { if (-not [string]::IsNullOrWhiteSpace([string]$Value)) { $Users.Add([string]$Value) } }

if (-not $Guilds.Contains($GuildId)) { $Guilds.Add($GuildId) }
if (-not $Channels.Contains($ChannelId)) { $Channels.Add($ChannelId) }
if (-not $Users.Contains($UserId)) { $Users.Add($UserId) }

$Updated = [ordered]@{
    schema_version = [string]$Allowlist.schema_version
    guilds = @($Guilds)
    channels = @($Channels)
    users = @($Users)
    notes = "Explicitly configured AI Office Discord allowlist."
}

Write-AIOfficeDiscordJson -Value $Updated -Path $Path

Write-Host "Discord allowlist updated." -ForegroundColor Green
return [pscustomobject]$Updated
