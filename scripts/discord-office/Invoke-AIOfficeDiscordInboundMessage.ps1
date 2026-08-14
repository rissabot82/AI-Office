param(
    [Parameter(Mandatory=$true)][string]$DiscordMessageId,
    [Parameter(Mandatory=$true)][string]$DiscordUserId,
    [Parameter(Mandatory=$true)][string]$DiscordGuildId,
    [Parameter(Mandatory=$true)][string]$DiscordChannelId,
    [Parameter(Mandatory=$true)][string]$Content
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"
. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscordRuntime.Common.ps1"

$Auth = & "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordAuthorization.ps1" `
    -DiscordUserId $DiscordUserId `
    -DiscordGuildId $DiscordGuildId `
    -DiscordChannelId $DiscordChannelId

if (-not [bool]$Auth.authorized) {
    throw "Discord message rejected by AI Office allowlist policy."
}

if ($Content.Trim().StartsWith("/")) {
    $CommandResult = & "E:\AI\AI-Office\scripts\discord-office\Invoke-AIOfficeDiscordCommand.ps1" `
        -CommandText $Content `
        -DiscordUserId $DiscordUserId `
        -DiscordGuildId $DiscordGuildId `
        -DiscordChannelId $DiscordChannelId

    if ([bool]$CommandResult.handled) {
        Send-AIOfficeDiscordChannelMessage -ChannelId $DiscordChannelId -Content ([string]$CommandResult.response) | Out-Null
        return [pscustomobject]@{
            command = [string]$CommandResult.command
            handled_as_command = $true
            response = [string]$CommandResult.response
        }
    }
}

$Mapping = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordSessionMapping.ps1" `
    -DiscordUserId $DiscordUserId `
    -DiscordChannelId $DiscordChannelId

if ($null -eq $Mapping) {
    $Conversation = & "E:\AI\AI-Office\scripts\conversational-office\New-AIOfficeConversationSession.ps1" -Title "Discord Conversation"
    $Mapping = & "E:\AI\AI-Office\scripts\discord-office\New-AIOfficeDiscordSessionMapping.ps1" `
        -DiscordUserId $DiscordUserId `
        -DiscordGuildId $DiscordGuildId `
        -DiscordChannelId $DiscordChannelId `
        -ConversationSessionId ([string]$Conversation.session_id)
}

$Inbound = & "E:\AI\AI-Office\scripts\discord-office\New-AIOfficeDiscordMessageEvent.ps1" `
    -Direction "inbound" `
    -DiscordMessageId $DiscordMessageId `
    -DiscordUserId $DiscordUserId `
    -DiscordGuildId $DiscordGuildId `
    -DiscordChannelId $DiscordChannelId `
    -ConversationSessionId ([string]$Mapping.conversation_session_id) `
    -Content $Content

$Result = & "E:\AI\AI-Office\scripts\discord-office\Invoke-AIOfficeDiscordRoutedTurn.ps1" `
    -SessionId ([string]$Mapping.conversation_session_id) `
    -Content $Content

Send-AIOfficeDiscordChannelMessage -ChannelId $DiscordChannelId -Content ([string]$Result.response) | Out-Null

$Outbound = & "E:\AI\AI-Office\scripts\discord-office\New-AIOfficeDiscordMessageEvent.ps1" `
    -Direction "outbound" `
    -DiscordMessageId ("LOCAL-" + [guid]::NewGuid().ToString("N").Substring(0,12)) `
    -DiscordUserId $DiscordUserId `
    -DiscordGuildId $DiscordGuildId `
    -DiscordChannelId $DiscordChannelId `
    -ConversationSessionId ([string]$Mapping.conversation_session_id) `
    -Content ([string]$Result.response)

return [pscustomobject]@{
    conversation_session_id = [string]$Mapping.conversation_session_id
    department = [string]$Result.department
    routing_reason = [string]$Result.routing_reason
    inbound_event_id = [string]$Inbound.event_id
    outbound_event_id = [string]$Outbound.event_id
    provider = [string]$Result.provider
    model = [string]$Result.model
    response = [string]$Result.response
    handled_as_command = $false
}
