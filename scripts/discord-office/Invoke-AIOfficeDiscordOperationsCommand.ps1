param(
    [Parameter(Mandatory=$true)][string]$CommandText
)

$ErrorActionPreference = "Stop"

$Text = $CommandText.Trim().ToLowerInvariant()

switch -Regex ($Text) {
    '^/ops$' {
        $Status = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1"

        return [pscustomobject]@{
            handled = $true
            command = "ops"
            response = (
                "AI Office operations: {0}. Discord={1}; Worker={2}; Processed={3}; Errors={4}; Self-hosting={5}; Ollama={6}; Gateway={7}; Dashboard={8}." -f
                $Status.status,
                $Status.discord_connected,
                $Status.worker_status,
                $Status.worker_processed_messages,
                $Status.worker_errors,
                $Status.self_hosting_status,
                $Status.ollama,
                $Status.openclaw_gateway,
                $Status.dashboard
            )
        }
    }

    '^/worker$' {
        $State = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordWorkerState.ps1"

        return [pscustomobject]@{
            handled = $true
            command = "worker"
            response = "Discord worker: status=$($State.status); processed=$($State.processed_messages); errors=$($State.errors); last poll=$($State.last_poll_at)."
        }
    }

    default {
        return [pscustomobject]@{
            handled = $false
            command = ""
            response = ""
        }
    }
}
