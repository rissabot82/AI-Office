param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE OPENCLAW BRIDGE STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Bridge ID          : " + [string]$Index.bridge_id)
Write-Host ("Status             : " + [string]$Index.status)
Write-Host ("Gateway URL        : " + [string]$Index.gateway_url)
Write-Host ("Gateway reachable  : " + [string]$Index.gateway_reachable)
Write-Host ("Pending requests   : " + [string]$Index.pending_request_count)
Write-Host ("Completed results  : " + [string]$Index.completed_result_count)
Write-Host ("Artifacts          : " + [string]$Index.artifact_count)
Write-Host ("Latest request     : " + [string]$Index.latest_request_id)
Write-Host ("Latest result      : " + [string]$Index.latest_result_id)
Write-Host ""

return $Index
