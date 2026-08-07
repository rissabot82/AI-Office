param(
    [Parameter(Mandatory=$true)][string]$AuthorId,
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$ChannelId = "",
    [string]$Priority = "normal",
    [string]$RequestedDepartment = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"
. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperationalRuntime.Common.ps1"

$Policy = Get-AIOfficeOperationalRuntimePolicy

if (-not [bool]$Policy.discord.enabled) {
    throw "Discord intake is disabled by policy."
}

$Trimmed = $Content.Trim()

if ([string]::IsNullOrWhiteSpace($Trimmed)) {
    throw "Discord task content cannot be empty."
}

$Title = $Trimmed

if ($Title.Length -gt 80) {
    $Title = $Title.Substring(0,80)
}

$DiscordId = New-AIOfficeOperationalRuntimeId -Prefix "OPSDIS"

$DiscordRecord = [ordered]@{
    discord_intake_id = $DiscordId
    author_id = $AuthorId
    channel_id = $ChannelId
    content = $Trimmed
    normalized_title = $Title
    priority = $Priority
    requested_department = $RequestedDepartment
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeOperationsJson `
    -Value $DiscordRecord `
    -Path "E:\AI\AI-Office\workspace\operations-integrations\discord-intake\$DiscordId.json"

$Intake = & "E:\AI\AI-Office\scripts\operations-integrations\New-AIOfficeOperationalIntake.ps1" `
    -Channel "discord" `
    -Title $Title `
    -Description $Trimmed `
    -Priority $Priority `
    -RequestedDepartment $RequestedDepartment `
    -SourceRef $DiscordId `
    -MetadataJson ('{"discord_author_id":"' + $AuthorId.Replace('"','') + '","discord_channel_id":"' + $ChannelId.Replace('"','') + '"}')

Write-Host "Discord task normalized: $DiscordId -> $($Intake.intake_id)" -ForegroundColor Green

return [pscustomobject]@{
    discord = [pscustomobject]$DiscordRecord
    intake = $Intake
}
