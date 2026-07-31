param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE DEPARTMENT INTELLIGENCE STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Departments        : " + [string]$Index.department_count)
Write-Host ("Active departments : " + [string]$Index.active_department_count)
Write-Host ("Inbox items        : " + [string]$Index.total_inbox_count)
Write-Host ("Plans              : " + [string]$Index.total_plan_count)
Write-Host ("Active work        : " + [string]$Index.total_active_work_count)
Write-Host ("Knowledge items    : " + [string]$Index.total_knowledge_item_count)
Write-Host ""

$Index.departments |
    Select-Object `
        department,
        status,
        inbox_count,
        plan_count,
        active_work_count,
        knowledge_item_count |
    Format-Table -AutoSize

return $Index
