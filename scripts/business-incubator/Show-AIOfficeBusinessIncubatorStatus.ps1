param()

$ErrorActionPreference = "Stop"

$Index = & "E:\AI\AI-Office\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE BUSINESS INCUBATOR" -ForegroundColor Cyan
Write-Host ("=" * 68)
Write-Host ("Ideas                  : " + [string]$Index.idea_count)
Write-Host ("Active ideas           : " + [string]$Index.active_idea_count)
Write-Host ("Research records       : " + [string]$Index.research_record_count)
Write-Host ("Validation experiments : " + [string]$Index.validation_experiment_count)
Write-Host ("Launch plans           : " + [string]$Index.launch_plan_count)
Write-Host ("Average score          : " + [string]$Index.average_opportunity_score)
Write-Host ""

return $Index
