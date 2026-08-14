param()

$ErrorActionPreference = "Stop"

$Status = & "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeIntelligenceOperationsStatus.ps1"

Write-Host ""
Write-Host "AI OFFICE INTELLIGENCE OPERATIONS" -ForegroundColor Cyan
Write-Host "================================="
Write-Host ("Tracked selections         : " + [string]$Status.tracked_selections)
Write-Host ("Intelligent turns          : " + [string]$Status.intelligent_turns)
Write-Host ("Fallback turns             : " + [string]$Status.fallback_turns)
Write-Host ("Escalation recommendations : " + [string]$Status.escalation_recommendations)
Write-Host ""

if ($Status.model_usage.PSObject.Properties.Count -gt 0) {
    Write-Host "Model usage:" -ForegroundColor Yellow
    foreach ($Property in $Status.model_usage.PSObject.Properties) {
        Write-Host ("  " + $Property.Name + " = " + [string]$Property.Value)
    }
    Write-Host ""
}

if ($Status.family_usage.PSObject.Properties.Count -gt 0) {
    Write-Host "Task-family usage:" -ForegroundColor Yellow
    foreach ($Property in $Status.family_usage.PSObject.Properties) {
        Write-Host ("  " + $Property.Name + " = " + [string]$Property.Value)
    }
    Write-Host ""
}

return $Status
