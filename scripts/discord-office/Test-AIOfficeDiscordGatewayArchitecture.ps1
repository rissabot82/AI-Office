param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part A Discord Gateway Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\discord-office\discord-policy.json",
    ".\config\discord-office\discord-allowlist.json",
    ".\config\discord-office\discord-message-schema.json",
    ".\config\discord-office\discord-session-map-schema.json",
    ".\config\discord-office\discord-runtime-state-schema.json",
    ".\workspace\discord-office\indexes\discord-index.json",
    ".\workspace\discord-office\state\runtime-state.json",
    ".\workspace\templates\discord-message-template.json",
    ".\workspace\templates\discord-session-map-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\discord-office\AIOfficeDiscord.Common.ps1",
    ".\scripts\discord-office\New-AIOfficeDiscordMessageEvent.ps1",
    ".\scripts\discord-office\New-AIOfficeDiscordSessionMapping.ps1",
    ".\scripts\discord-office\Get-AIOfficeDiscordSessionMapping.ps1",
    ".\scripts\discord-office\Update-AIOfficeDiscordIndex.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordAuthorization.ps1",
    ".\scripts\discord-office\Get-AIOfficeDiscordStatus.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordGatewayArchitecture.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING SCRIPT] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$Created = New-Object System.Collections.Generic.List[string]

try {
    $Conversation = & ".\scripts\conversational-office\New-AIOfficeConversationSession.ps1" `
        -Title "Discord Architecture Certification"

    $ConversationPath = "E:\AI\AI-Office\workspace\conversational-office\sessions\$($Conversation.session_id).json"
    $Created.Add($ConversationPath)

    $Mapping = & ".\scripts\discord-office\New-AIOfficeDiscordSessionMapping.ps1" `
        -DiscordUserId "CERT-USER" `
        -DiscordGuildId "CERT-GUILD" `
        -DiscordChannelId "CERT-CHANNEL" `
        -ConversationSessionId ([string]$Conversation.session_id)

    $MappingPath = "E:\AI\AI-Office\workspace\discord-office\session-maps\$($Mapping.mapping_id).json"
    $Created.Add($MappingPath)

    $Inbound = & ".\scripts\discord-office\New-AIOfficeDiscordMessageEvent.ps1" `
        -Direction "inbound" `
        -DiscordMessageId "CERT-INBOUND" `
        -DiscordUserId "CERT-USER" `
        -DiscordGuildId "CERT-GUILD" `
        -DiscordChannelId "CERT-CHANNEL" `
        -ConversationSessionId ([string]$Conversation.session_id) `
        -Content "Discord certification message"

    $InboundPath = "E:\AI\AI-Office\workspace\discord-office\events\inbound\$($Inbound.event_id).json"
    $Created.Add($InboundPath)

    $LoadedMapping = & ".\scripts\discord-office\Get-AIOfficeDiscordSessionMapping.ps1" `
        -DiscordUserId "CERT-USER" `
        -DiscordChannelId "CERT-CHANNEL"

    if ($null -eq $LoadedMapping) {
        throw "Discord session mapping retrieval failed."
    }

    if ([string]$LoadedMapping.conversation_session_id -ne [string]$Conversation.session_id) {
        throw "Discord session mapping points to the wrong conversation."
    }

    $Authorization = & ".\scripts\discord-office\Test-AIOfficeDiscordAuthorization.ps1" `
        -DiscordUserId "CERT-USER" `
        -DiscordGuildId "CERT-GUILD" `
        -DiscordChannelId "CERT-CHANNEL"

    if ([bool]$Authorization.authorized) {
        throw "Default-deny authorization failed. Empty allowlist must reject certification IDs."
    }

    Write-Host "[MAPPING OK] Discord-to-conversation mapping passed." -ForegroundColor Green
    Write-Host "[EVENT OK] Discord event persistence passed." -ForegroundColor Green
    Write-Host "[SECURITY OK] Default-deny authorization passed." -ForegroundColor Green
}
catch {
    Write-Host "[DISCORD ARCH ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}
finally {
    foreach ($File in $Created) {
        Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue
    }

    & ".\scripts\discord-office\Update-AIOfficeDiscordIndex.ps1" | Out-Null
    & ".\scripts\conversational-office\Update-AIOfficeConversationIndex.ps1" | Out-Null
}

try {
    $Status = & ".\scripts\discord-office\Get-AIOfficeDiscordStatus.ps1"

    $ValidStates = @(
        "not_connected",
        "connected",
        "degraded",
        "offline"
    )

    if ($ValidStates -notcontains [string]$Status.status) {
        throw "Discord architecture returned an invalid runtime state: $($Status.status)"
    }

    Write-Host "[STATUS OK] Discord architecture status available: $($Status.status)" -ForegroundColor Green
}
catch {
    Write-Host "[STATUS ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Discord Gateway Architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part A Discord Gateway Architecture checks passed." -ForegroundColor Green

