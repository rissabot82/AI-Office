param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Index = & ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE LONG-TERM MEMORY STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Status            : " + [string]$Index.status)
Write-Host ("Total memories    : " + [string]$Index.total_memory_count)
Write-Host ("Active memories   : " + [string]$Index.active_memory_count)
Write-Host ("Archived memories : " + [string]$Index.archived_memory_count)
Write-Host ("Latest memory     : " + [string]$Index.latest_memory_id)
Write-Host ""

return $Index
