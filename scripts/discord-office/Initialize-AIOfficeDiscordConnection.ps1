param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"
. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscordRuntime.Common.ps1"

$Me = Invoke-AIOfficeDiscordApi -Method "GET" -Path "users/@me"
$Guilds = Invoke-AIOfficeDiscordApi -Method "GET" -Path "users/@me/guilds"

$StatePath = "E:\AI\AI-Office\workspace\discord-office\state\runtime-state.json"
$State = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json

$State.status = "connected"
$State.connected = $true
$State.configured = $true
$State.bot_user_id = [string]$Me.id
$State.bot_username = [string]$Me.username
$State.last_connected_at = (Get-Date).ToString("o")
$State.updated_at = (Get-Date).ToString("o")

Write-AIOfficeDiscordJson -Value $State -Path $StatePath

$Connection = [ordered]@{
    status = "connected"
    bot_user_id = [string]$Me.id
    bot_username = [string]$Me.username
    guild_count = @($Guilds).Count
    connected_at = $State.last_connected_at
    updated_at = $State.updated_at
}

Write-AIOfficeDiscordJson `
    -Value $Connection `
    -Path "E:\AI\AI-Office\workspace\discord-office\state\connection.json"

Write-Host "Discord connection initialized: $($Connection.bot_username) | guilds=$($Connection.guild_count)" -ForegroundColor Green
return [pscustomobject]$Connection
