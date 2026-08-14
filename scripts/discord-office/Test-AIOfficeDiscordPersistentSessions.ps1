param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part C Persistent Sessions and Commands..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    Get-Content ".\config\discord-office\command-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\discord-office\command-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid command policy JSON.")
}

$Scripts = @(
    ".\scripts\discord-office\Reset-AIOfficeDiscordSession.ps1",
    ".\scripts\discord-office\Get-AIOfficeDiscordConversationHistory.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordCommand.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordInboundMessage.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordPersistentSessions.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

$Created = New-Object System.Collections.Generic.List[string]

try {
    $Conversation = & ".\scripts\conversational-office\New-AIOfficeConversationSession.ps1" `
        -Title "Discord Part C Certification"

    $Created.Add("E:\AI\AI-Office\workspace\conversational-office\sessions\$($Conversation.session_id).json")

    $Map = & ".\scripts\discord-office\New-AIOfficeDiscordSessionMapping.ps1" `
        -DiscordUserId "PARTC-USER" `
        -DiscordGuildId "PARTC-GUILD" `
        -DiscordChannelId "PARTC-CHANNEL" `
        -ConversationSessionId ([string]$Conversation.session_id)

    $Created.Add("E:\AI\AI-Office\workspace\discord-office\session-maps\$($Map.mapping_id).json")

    $SessionCommand = & ".\scripts\discord-office\Invoke-AIOfficeDiscordCommand.ps1" `
        -CommandText "/session" `
        -DiscordUserId "PARTC-USER" `
        -DiscordGuildId "PARTC-GUILD" `
        -DiscordChannelId "PARTC-CHANNEL"

    if (-not [bool]$SessionCommand.handled) {
        throw "/session was not handled."
    }

    if (-not ([string]$SessionCommand.response).Contains([string]$Conversation.session_id)) {
        throw "/session returned the wrong session."
    }

    Write-Host "[SESSION COMMAND OK]" -ForegroundColor Green

    $Help = & ".\scripts\discord-office\Invoke-AIOfficeDiscordCommand.ps1" `
        -CommandText "/help" `
        -DiscordUserId "PARTC-USER" `
        -DiscordGuildId "PARTC-GUILD" `
        -DiscordChannelId "PARTC-CHANNEL"

    if (-not ([string]$Help.response).Contains("/new")) {
        throw "/help output is incomplete."
    }

    Write-Host "[HELP COMMAND OK]" -ForegroundColor Green

    $Reset = & ".\scripts\discord-office\Reset-AIOfficeDiscordSession.ps1" `
        -DiscordUserId "PARTC-USER" `
        -DiscordGuildId "PARTC-GUILD" `
        -DiscordChannelId "PARTC-CHANNEL" `
        -Title "Discord Part C Replacement"

    $Created.Add("E:\AI\AI-Office\workspace\conversational-office\sessions\$($Reset.conversation.session_id).json")
    $Created.Add("E:\AI\AI-Office\workspace\discord-office\session-maps\$($Reset.mapping.mapping_id).json")

    if ([string]$Reset.conversation.session_id -eq [string]$Conversation.session_id) {
        throw "/new behavior did not create a replacement session."
    }

    Write-Host "[NEW SESSION OK] $($Reset.conversation.session_id)" -ForegroundColor Green

    $Current = & ".\scripts\discord-office\Get-AIOfficeDiscordSessionMapping.ps1" `
        -DiscordUserId "PARTC-USER" `
        -DiscordChannelId "PARTC-CHANNEL"

    if ([string]$Current.conversation_session_id -ne [string]$Reset.conversation.session_id) {
        throw "Persistent session mapping did not update."
    }

    Write-Host "[PERSISTENCE OK] Active Discord session mapping passed." -ForegroundColor Green
}
catch {
    Write-Host "[PART C ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}
finally {
    foreach ($File in $Created) {
        Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue
    }

    Get-ChildItem `
        "E:\AI\AI-Office\workspace\discord-office\session-maps\DCMAP-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        try {
            $Map = Get-Content $_.FullName -Raw | ConvertFrom-Json
            if ([string]$Map.discord_user_id -eq "PARTC-USER") {
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }

    & ".\scripts\discord-office\Update-AIOfficeDiscordIndex.ps1" | Out-Null
    & ".\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1" | Out-Null
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Persistent Sessions and Commands error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part C Persistent Sessions and Commands checks passed." -ForegroundColor Green
