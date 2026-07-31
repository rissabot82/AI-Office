param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE MESSAGE BUS STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Total       : " + [string]$Index.total_messages)
Write-Host ("Inbox       : " + [string]$Index.inbox_count)
Write-Host ("Outbox      : " + [string]$Index.outbox_count)
Write-Host ("Processing  : " + [string]$Index.processing_count)
Write-Host ("Processed   : " + [string]$Index.processed_count)
Write-Host ("Failed      : " + [string]$Index.failed_count)
Write-Host ("Dead-letter : " + [string]$Index.dead_letter_count)
Write-Host ("Archive     : " + [string]$Index.archive_count)
Write-Host ("Latest      : " + [string]$Index.latest_message_id)
Write-Host ""

return $Index
