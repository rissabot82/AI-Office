param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Index = & "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1"

$Recommendations = New-Object System.Collections.Generic.List[object]

if ([double]$Index.monthly_net -lt 0) {
    $Recommendations.Add([pscustomobject]@{
        priority = "high"
        category = "cash_flow"
        recommendation = "Monthly expenses currently exceed recorded monthly income."
    })
}

if ([double]$Index.total_debt_balance -gt 0 -and [double]$Index.total_liquid_balance -lt 500) {
    $Recommendations.Add([pscustomobject]@{
        priority = "high"
        category = "cash_buffer"
        recommendation = "Build a larger liquid cash buffer before accelerating discretionary debt payments."
    })
}

if ([double]$Index.total_goal_target -gt 0) {
    $Progress = if ([double]$Index.total_goal_target -gt 0) {
        ([double]$Index.total_goal_progress / [double]$Index.total_goal_target) * 100.0
    } else { 0.0 }

    $Recommendations.Add([pscustomobject]@{
        priority = "normal"
        category = "goals"
        recommendation = ("Financial goals are " + [math]::Round($Progress,1) + "% funded.")
    })
}

if ($Recommendations.Count -eq 0) {
    $Recommendations.Add([pscustomobject]@{
        priority = "normal"
        category = "status"
        recommendation = "No immediate financial risk flags were detected from the current records."
    })
}

$Id = "FINREC-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$(([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpperInvariant())"

$Record = [ordered]@{
    recommendation_id = $Id
    generated_at = (Get-Date).ToString("o")
    recommendations = @($Recommendations | ForEach-Object { $_ })
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\recommendations\$Id.json"

Write-Host "Financial recommendations generated: $($Recommendations.Count)" -ForegroundColor Green
return [pscustomobject]$Record
