param(
    [Parameter(Mandatory=$true)]$QualityRun
)

Write-Host ""
Write-Host "AI OFFICE INTELLIGENCE QUALITY REPORT" -ForegroundColor Cyan
Write-Host "====================================="
Write-Host ""

$Rank = 1

foreach ($Model in @($QualityRun.rankings)) {
    Write-Host ("#" + $Rank + " " + [string]$Model.model) -ForegroundColor Yellow
    Write-Host ("  Average score : " + [string]$Model.average_score)
    Write-Host ("  Passed cases  : " + [string]$Model.passed_cases + "/" + [string]$Model.total_cases)

    foreach ($Property in $Model.family_scores.PSObject.Properties) {
        Write-Host ("  " + $Property.Name.PadRight(14) + ": " + [string]$Property.Value)
    }

    Write-Host ""
    $Rank++
}
