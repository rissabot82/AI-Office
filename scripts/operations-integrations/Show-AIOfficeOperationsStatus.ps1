param()

$ErrorActionPreference = "Stop"

$Index = & "E:\AI\AI-Office\scripts\operations-integrations\Update-AIOfficeOperationsIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE OPERATIONS & INTEGRATIONS" -ForegroundColor Cyan
Write-Host ("=" * 68)
Write-Host ("Intake items            : " + [string]$Index.intake_count)
Write-Host ("Queued intake           : " + [string]$Index.queued_intake_count)
Write-Host ("Integrations            : " + [string]$Index.integration_count)
Write-Host ("Connected integrations  : " + [string]$Index.connected_integration_count)
Write-Host ("Jobs                    : " + [string]$Index.job_count)
Write-Host ("Active jobs             : " + [string]$Index.active_job_count)
Write-Host ("Notifications           : " + [string]$Index.notification_count)
Write-Host ("Unread notifications    : " + [string]$Index.unread_notification_count)
Write-Host ""

return $Index
