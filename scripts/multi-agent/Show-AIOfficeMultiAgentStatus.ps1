param()

$ErrorActionPreference = "Stop"

$Index = & "E:\AI\AI-Office\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE MULTI-AGENT STATUS" -ForegroundColor Cyan
Write-Host ("=" * 64)
Write-Host ("Agents                 : " + [string]$Index.agent_count)
Write-Host ("Available              : " + [string]$Index.available_count)
Write-Host ("Busy                   : " + [string]$Index.busy_count)
Write-Host ("Assignments            : " + [string]$Index.assignment_count)
Write-Host ("Open assignments       : " + [string]$Index.open_assignment_count)
Write-Host ("Collaborations         : " + [string]$Index.collaboration_count)
Write-Host ("Active collaborations  : " + [string]$Index.active_collaboration_count)
Write-Host ""

return $Index
