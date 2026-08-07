param(
    [Parameter(Mandatory=$true)][string]$IdeaId,
    [Parameter(Mandatory=$true)][double]$LaunchBudget,
    [Parameter(Mandatory=$true)][double]$ExpectedMonthlyRevenue,
    [double]$ExpectedMonthlyExpenses = 0.0
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeVenturePlanning.Common.ps1"

$Idea = Get-AIOfficeBusinessIdeaById -IdeaId $IdeaId

$MonthlyProfit = $ExpectedMonthlyRevenue - $ExpectedMonthlyExpenses

$MonthsToBreakEven = if ($MonthlyProfit -gt 0) {
    $LaunchBudget / $MonthlyProfit
}
else {
    -1
}

$Id = New-AIOfficeVenturePlanningId -Prefix "BIZBUD"

$Record = [ordered]@{
    budget_analysis_id = $Id
    idea_id = $IdeaId
    idea_name = [string]$Idea.name
    launch_budget = [math]::Round([math]::Abs($LaunchBudget),2)
    expected_monthly_revenue = [math]::Round($ExpectedMonthlyRevenue,2)
    expected_monthly_expenses = [math]::Round($ExpectedMonthlyExpenses,2)
    expected_monthly_profit = [math]::Round($MonthlyProfit,2)
    months_to_break_even = if ($MonthsToBreakEven -ge 0) { [math]::Round($MonthsToBreakEven,2) } else { -1 }
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\budget-analysis\$Id.json"

Write-Host "Launch budget analysis created: $Id | monthly profit=$($Record.expected_monthly_profit)" -ForegroundColor Green
return [pscustomobject]$Record
