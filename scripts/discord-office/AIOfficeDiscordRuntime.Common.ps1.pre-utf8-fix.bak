$script:AIOfficeDiscordRuntimeRoot = "E:\AI\AI-Office"

function Get-AIOfficeDiscordLiveRuntimePolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\discord-office\live-runtime-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Get-AIOfficeDiscordBotToken {
    . "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

    $Policy = Get-AIOfficeDiscordPolicy
    $Name = [string]$Policy.security.token_environment_variable

    $Token = [Environment]::GetEnvironmentVariable($Name, "User")
    if ([string]::IsNullOrWhiteSpace($Token)) {
        $Token = [Environment]::GetEnvironmentVariable($Name, "Process")
    }

    if ([string]::IsNullOrWhiteSpace($Token)) {
        throw "Discord bot token is not configured in environment variable $Name."
    }

    return $Token
}

function Invoke-AIOfficeDiscordApi {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("GET","POST","PUT","PATCH","DELETE")][string]$Method,
        [Parameter(Mandatory=$true)][string]$Path,
        $Body = $null
    )

    $Policy = Get-AIOfficeDiscordLiveRuntimePolicy
    $Token = Get-AIOfficeDiscordBotToken
    $Uri = ([string]$Policy.discord.api_base).TrimEnd("/") + "/" + $Path.TrimStart("/")

    $Headers = @{
        Authorization = "Bot $Token"
        "User-Agent" = "AI-Office/2.4"
    }

    if ($null -eq $Body) {
        return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -TimeoutSec 60
    }

    return Invoke-RestMethod `
        -Uri $Uri `
        -Method $Method `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($Body | ConvertTo-Json -Depth 20 -Compress) `
        -TimeoutSec 60
}

function Send-AIOfficeDiscordChannelMessage {
    param(
        [Parameter(Mandatory=$true)][string]$ChannelId,
        [Parameter(Mandatory=$true)][string]$Content
    )

    . "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"

    $Policy = Get-AIOfficeDiscordPolicy
    $Max = [int]$Policy.limits.max_discord_reply_characters

    $Chunks = New-Object System.Collections.Generic.List[string]
    $Remaining = $Content

    while ($Remaining.Length -gt $Max) {
        $Cut = $Remaining.LastIndexOf("`n", [math]::Min($Max, $Remaining.Length - 1))
        if ($Cut -lt [math]::Floor($Max * 0.5)) {
            $Cut = $Max
        }

        $Chunks.Add($Remaining.Substring(0, $Cut))
        $Remaining = $Remaining.Substring($Cut).TrimStart()
    }

    if (-not [string]::IsNullOrWhiteSpace($Remaining)) {
        $Chunks.Add($Remaining)
    }

    $Responses = New-Object System.Collections.Generic.List[object]

    foreach ($Chunk in $Chunks) {
        $Response = Invoke-AIOfficeDiscordApi `
            -Method "POST" `
            -Path "channels/$ChannelId/messages" `
            -Body @{ content = $Chunk }

        $Responses.Add($Response)
    }

    return @($Responses | ForEach-Object { $_ })
}
