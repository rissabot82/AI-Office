param()

$ErrorActionPreference = "Stop"

$Index = & "E:\AI\AI-Office\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE AUTONOMOUS ENTERPRISE" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Enterprise Work Items : " + [string]$Index.work_item_count)
Write-Host ("Active Work Items     : " + [string]$Index.active_work_item_count)
Write-Host ("Enterprise Plans      : " + [string]$Index.plan_count)
Write-Host ("Active Plans          : " + [string]$Index.active_plan_count)
Write-Host ("Departments           : " + [string]$Index.department_count)
Write-Host ("Capabilities          : " + [string]$Index.capability_count)
Write-Host ""

return $Index
