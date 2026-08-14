param(
    [Parameter(Mandatory=$true)][string]$Content
)

$ErrorActionPreference = "Stop"

$Selection = & "E:\AI\AI-Office\scripts\intelligence\Select-AIOfficeIntelligentModel.ps1" `
    -Content $Content

$Complexity = if ($Content.Length -gt 500) { "high" } elseif ($Content.Length -gt 180) { "medium" } else { "low" }

$Escalation = & "E:\AI\AI-Office\scripts\intelligence\Resolve-AIOfficeQualityEscalation.ps1" `
    -Content $Content `
    -TaskFamily ([string]$Selection.task_family) `
    -SelectedModel ([string]$Selection.selected_model) `
    -ModelScore ([double]$Selection.score) `
    -Complexity $Complexity

Write-Host ""
Write-Host "AI Office Quality Escalation" -ForegroundColor Cyan
Write-Host "-----------------------------"
Write-Host ("Task family:        " + $Escalation.task_family)
Write-Host ("Local model:        " + $Escalation.selected_model)
Write-Host ("Local score:        " + $Escalation.local_score)
Write-Host ("Quality threshold:  " + $Escalation.quality_threshold)
Write-Host ("Escalation advised: " + $Escalation.requires_escalation)
Write-Host ("Advisory only:      " + $Escalation.advisory_only)

if (@($Escalation.reasons).Count -gt 0) {
    Write-Host "Reasons:" -ForegroundColor Yellow
    foreach ($Reason in @($Escalation.reasons)) {
        Write-Host ("  - " + $Reason)
    }
}

return $Escalation
