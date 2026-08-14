param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscord.Common.ps1"
. "E:\AI\AI-Office\scripts\discord-office\AIOfficeDiscordRuntime.Common.ps1"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\discord-office\worker-policy.json" `
    -Raw |
    ConvertFrom-Json

$StatePath = "E:\AI\AI-Office\workspace\discord-office\state\worker-state.json"
$State = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json

function Save-WorkerState {
    param($Value)
    $Value.updated_at = (Get-Date).ToString("o")
    $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $StatePath -Encoding UTF8
}

$State.status = "running"
$State.started_at = (Get-Date).ToString("o")
$State.last_error = ""
Save-WorkerState -Value $State

Start-Sleep -Seconds ([int]$Policy.worker.startup_delay_seconds)

try {
    while ($true) {
        try {
            $Connection = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordStatus.ps1"

            if (-not [bool]$Connection.connected) {
                throw "Discord connection is not configured or healthy."
            }

            $Allowlist = Get-Content `
                -LiteralPath "E:\AI\AI-Office\config\discord-office\allowlist.json" `
                -Raw |
                ConvertFrom-Json

            foreach ($ChannelId in @($Allowlist.allowed_channel_ids)) {
                if ([string]::IsNullOrWhiteSpace([string]$ChannelId)) { continue }

                $ApiPath = "channels/$ChannelId/messages?limit=$([int]$Policy.worker.max_messages_per_cycle)"
                $Messages = Invoke-AIOfficeDiscordApi -Method "GET" -Path $ApiPath

                $Ordered = @($Messages | Sort-Object { [decimal]$_.id })

                foreach ($Message in $Ordered) {
                    if ([bool]$Policy.worker.ignore_bot_messages -and [bool]$Message.author.bot) {
                        continue
                    }

                    if (-not [string]::IsNullOrWhiteSpace([string]$State.last_message_id)) {
                        try {
                            if ([decimal]$Message.id -le [decimal]$State.last_message_id) {
                                continue
                            }
                        }
                        catch {}
                    }

                    try {
                        & "E:\AI\AI-Office\scripts\discord-office\Invoke-AIOfficeDiscordInboundMessage.ps1" `
                            -DiscordMessageId ([string]$Message.id) `
                            -DiscordUserId ([string]$Message.author.id) `
                            -DiscordGuildId ([string]$Allowlist.allowed_guild_ids[0]) `
                            -DiscordChannelId ([string]$ChannelId) `
                            -Content ([string]$Message.content) |
                            Out-Null

                        $State.last_message_id = [string]$Message.id
                        $State.processed_messages = [long]$State.processed_messages + 1
                        $State.last_error = ""
                        Save-WorkerState -Value $State
                    }
                    catch {
                        $MessageError = $_.Exception.Message

                        $State.errors = [long]$State.errors + 1
                        $State.last_error = $MessageError

                        # Quarantine this Discord message instead of retrying it forever.
                        $State.last_message_id = [string]$Message.id

                        $FailedDirectory = "E:\AI\AI-Office\workspace\discord-office\failed-messages"
                        New-Item `
                            -ItemType Directory `
                            -Path $FailedDirectory `
                            -Force |
                            Out-Null

                        $FailedRecord = [ordered]@{
                            discord_message_id = [string]$Message.id
                            discord_user_id = [string]$Message.author.id
                            discord_channel_id = [string]$ChannelId
                            content = [string]$Message.content
                            error = $MessageError
                            quarantined_at = (Get-Date).ToString("o")
                        }

                        $FailedRecord |
                            ConvertTo-Json -Depth 20 |
                            Set-Content `
                                -LiteralPath (Join-Path $FailedDirectory ("FAILED-" + [string]$Message.id + ".json")) `
                                -Encoding UTF8

                        Save-WorkerState -Value $State

                        Write-Host (
                            "[QUARANTINED] Discord message " +
                            [string]$Message.id +
                            " | " +
                            $MessageError
                        ) -ForegroundColor Yellow

                        continue
                    }
                }
            }

            $State.last_poll_at = (Get-Date).ToString("o")
            $State.last_error = ""
            Save-WorkerState -Value $State
            Start-Sleep -Seconds ([int]$Policy.worker.poll_interval_seconds)
        }
        catch {
            $State.errors = [long]$State.errors + 1
            $State.last_error = $_.Exception.Message
            $State.last_poll_at = (Get-Date).ToString("o")
            Save-WorkerState -Value $State
            Start-Sleep -Seconds ([int]$Policy.worker.error_backoff_seconds)
        }
    }
}
finally {
    $State.status = "stopped"
    Save-WorkerState -Value $State
}



