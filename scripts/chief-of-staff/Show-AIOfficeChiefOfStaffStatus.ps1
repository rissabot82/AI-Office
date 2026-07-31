param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE CHIEF OF STAFF STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Status              : " + [string]$Index.status)
Write-Host ("Inbox               : " + [string]$Index.inbox_count)
Write-Host ("Open plans          : " + [string]$Index.open_plan_count)
Write-Host ("Pending approvals   : " + [string]$Index.pending_approval_count)
Write-Host ("Active delegations  : " + [string]$Index.active_delegation_count)
Write-Host ("Decisions           : " + [string]$Index.decision_count)
Write-Host ("Latest plan         : " + [string]$Index.latest_plan_id)
Write-Host ("Latest decision     : " + [string]$Index.latest_decision_id)
Write-Host ""

return $Index
