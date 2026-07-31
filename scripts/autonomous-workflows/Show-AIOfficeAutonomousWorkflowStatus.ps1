param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE AUTONOMOUS WORKFLOW STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Goals              : " + [string]$Index.goal_count)
Write-Host ("Open goals         : " + [string]$Index.open_goal_count)
Write-Host ("Plans              : " + [string]$Index.plan_count)
Write-Host ("Active runs        : " + [string]$Index.active_run_count)
Write-Host ("Waiting approvals  : " + [string]$Index.waiting_approval_count)
Write-Host ("Failed runs        : " + [string]$Index.failed_run_count)
Write-Host ("Latest goal        : " + [string]$Index.latest_goal_id)
Write-Host ("Latest run         : " + [string]$Index.latest_run_id)
Write-Host ""

return $Index
