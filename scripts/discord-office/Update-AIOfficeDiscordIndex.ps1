param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

$Inbound = Get-AIOfficeDiscordCollection `
    -Directory "E:\AI\AI-Office\workspace\discord-office\events\inbound" `
    -Filter "DCEVT-*.json"

$Outbound = Get-AIOfficeDiscordCollection `
    -Directory "E:\AI\AI-Office\workspace\discord-office\events\outbound" `
    -Filter "DCEVT-*.json"

$Mappings = Get-AIOfficeDiscordCollection `
    -Directory "E:\AI\AI-Office\workspace\discord-office\session-maps" `
    -Filter "DCMAP-*.json"

$Index = [ordered]@{
    inbound_event_count = @($Inbound).Count
    outbound_event_count = @($Outbound).Count
    session_mapping_count = @($Mappings).Count
    active_session_mapping_count = @(
        $Mappings | Where-Object { [string]$_.status -eq "active" }
    ).Count
    updated_at = (Get-Date).ToString("o")
}

Write-AIOfficeDiscordJson `
    -Value $Index `
    -Path "E:\AI\AI-Office\workspace\discord-office\indexes\discord-index.json"

return [pscustomobject]$Index
