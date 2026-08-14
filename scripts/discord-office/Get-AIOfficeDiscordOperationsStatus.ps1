param()

$ErrorActionPreference = "Stop"

$Worker = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1"
$Discord = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordStatus.ps1"

$SelfHosting = $null
$SelfHostingScript = "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingServiceHealth.ps1"

if (Test-Path -LiteralPath $SelfHostingScript) {
    try {
        $SelfHosting = & $SelfHostingScript
    }
    catch {
        $SelfHosting = [pscustomobject]@{
            status = "error"
            ollama = $false
            openclaw_gateway = $false
            dashboard = $false
        }
    }
}

$WorkerRunning = ([string]$Worker.status -eq "running")
$DiscordConnected = [bool]$Discord.connected

$Overall = if ($WorkerRunning -and $DiscordConnected) {
    "healthy"
}
elseif ($DiscordConnected -or $WorkerRunning) {
    "degraded"
}
else {
    "offline"
}

return [pscustomobject]@{
    status = $Overall
    discord_connected = $DiscordConnected
    worker_status = [string]$Worker.status
    worker_started_at = [string]$Worker.started_at
    worker_last_poll_at = [string]$Worker.last_poll_at
    worker_processed_messages = [long]$Worker.processed_messages
    worker_errors = [long]$Worker.errors
    worker_last_error = [string]$Worker.last_error
    self_hosting_status = if ($null -ne $SelfHosting) { [string]$SelfHosting.status } else { "unknown" }
    ollama = if ($null -ne $SelfHosting) { [bool]$SelfHosting.ollama } else { $false }
    openclaw_gateway = if ($null -ne $SelfHosting) { [bool]$SelfHosting.openclaw_gateway } else { $false }
    dashboard = if ($null -ne $SelfHosting) { [bool]$SelfHosting.dashboard } else { $false }
    checked_at = (Get-Date).ToString("o")
}
