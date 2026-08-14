param()

$ErrorActionPreference = "Stop"

$Status = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1"

Write-Host ""
Write-Host "AI Office Discord Operations" -ForegroundColor Cyan
Write-Host "----------------------------"
Write-Host "Overall:            $($Status.status)"
Write-Host "Discord connected:  $($Status.discord_connected)"
Write-Host "Worker:             $($Status.worker_status)"
Write-Host "Processed messages: $($Status.worker_processed_messages)"
Write-Host "Worker errors:      $($Status.worker_errors)"
Write-Host "Last poll:          $($Status.worker_last_poll_at)"
Write-Host "Self-hosting:       $($Status.self_hosting_status)"
Write-Host "Ollama:             $($Status.ollama)"
Write-Host "OpenClaw Gateway:   $($Status.openclaw_gateway)"
Write-Host "Dashboard:          $($Status.dashboard)"

if (-not [string]::IsNullOrWhiteSpace([string]$Status.worker_last_error)) {
    Write-Host "Last worker error:  $($Status.worker_last_error)" -ForegroundColor Yellow
}

Write-Host ""

return $Status
