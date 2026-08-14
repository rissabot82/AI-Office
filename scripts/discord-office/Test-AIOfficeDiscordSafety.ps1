param(
    [string]$DiscordUserId,
    [string]$DiscordGuildId,
    [string]$DiscordChannelId
)

$ErrorActionPreference = "Stop"

$Result = [ordered]@{
    safe = $true
    allowlist_checked = $false
    authorized = $false
    reasons = @()
    checked_at = (Get-Date).ToString("o")
}

try {
    if (
        -not [string]::IsNullOrWhiteSpace($DiscordUserId) -and
        -not [string]::IsNullOrWhiteSpace($DiscordGuildId) -and
        -not [string]::IsNullOrWhiteSpace($DiscordChannelId)
    ) {
        $Auth = & "E:\AI\AI-Office\scripts\discord-office\Test-AIOfficeDiscordAuthorization.ps1" `
            -DiscordUserId $DiscordUserId `
            -DiscordGuildId $DiscordGuildId `
            -DiscordChannelId $DiscordChannelId

        $Result.allowlist_checked = $true
        $Result.authorized = [bool]$Auth.authorized

        if (-not $Result.authorized) {
            $Result.safe = $false
            $Result.reasons = @("Discord identity/channel is not authorized by the AI Office allowlist.")
        }
    }
}
catch {
    $Result.safe = $false
    $Result.reasons = @($_.Exception.Message)
}

return [pscustomobject]$Result
