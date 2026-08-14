# AI Office v2.4 Part E — Discord Worker Service

Part E adds the continuously running Windows-side Discord worker.

The worker polls allowlisted Discord channels, ignores bot-authored messages, passes new messages into the v2.4 intake/routing pipeline, and persists its processing cursor so messages are not intentionally reprocessed after a normal restart.

Included lifecycle scripts:

- `Start-AIOfficeDiscordWorker.ps1`
- `Stop-AIOfficeDiscordWorker.ps1`
- `Get-AIOfficeDiscordWorkerState.ps1`
- `Install-AIOfficeDiscordWorkerStartup.ps1`

The startup installer creates a Windows Scheduled Task for the current Windows account. Run that script from an elevated PowerShell session when ready to enable automatic startup.
