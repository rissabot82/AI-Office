param(
    [Parameter(Mandatory=$true)]$Selection
)

Write-Host ""
Write-Host "AI OFFICE INTELLIGENT MODEL SELECTION" -ForegroundColor Cyan
Write-Host "====================================="
Write-Host ("Task family          : " + [string]$Selection.task_family)
Write-Host ("Quality tier         : " + [string]$Selection.quality_tier)
Write-Host ("Selected model       : " + [string]$Selection.selected_model)
Write-Host ("Family score         : " + [string]$Selection.selected_family_score)
Write-Host ("Required threshold   : " + [string]$Selection.quality_threshold)
Write-Host ("Requires escalation  : " + [string]$Selection.requires_escalation)
Write-Host ("Selection reason     : " + [string]$Selection.selection_reason)
Write-Host ""
