param(
    [Parameter(Mandatory=$true)][string]$IdeaId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeVenturePlanning.Common.ps1"

$Policy = Get-AIOfficeVenturePlanningPolicy
$Idea = Get-AIOfficeBusinessIdeaById -IdeaId $IdeaId

$Scores = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\scores" `
        -Filter "BIZSCORE-*.json" |
    Where-Object { [string]$_.idea_id -eq $IdeaId } |
    Sort-Object created_at -Descending
)

$ValidationResults = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\validation-results" `
        -Filter "BIZVR-*.json" |
    Where-Object { [string]$_.idea_id -eq $IdeaId } |
    Sort-Object created_at -Descending
)

$Budgets = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\budget-analysis" `
        -Filter "BIZBUD-*.json" |
    Where-Object { [string]$_.idea_id -eq $IdeaId } |
    Sort-Object created_at -Descending
)

$OpportunityScore = if ($Scores.Count -gt 0) {
    [double]$Scores[0].total_score
} else { 0.0 }

$ValidationScore = if ($ValidationResults.Count -gt 0) {
    [double]$ValidationResults[0].score
} else { 0.0 }

$BudgetScore = 50.0

if ($Budgets.Count -gt 0) {
    $Budget = $Budgets[0]

    if ([double]$Budget.expected_monthly_profit -gt 0) {
        if ([double]$Budget.months_to_break_even -le 3) {
            $BudgetScore = 100.0
        }
        elseif ([double]$Budget.months_to_break_even -le 6) {
            $BudgetScore = 85.0
        }
        elseif ([double]$Budget.months_to_break_even -le 12) {
            $BudgetScore = 70.0
        }
        else {
            $BudgetScore = 50.0
        }
    }
    else {
        $BudgetScore = 20.0
    }
}

$Composite = (
    ($OpportunityScore * 0.45) +
    ($ValidationScore * 0.35) +
    ($BudgetScore * 0.20)
)

$Recommendation = if (
    $Composite -ge [double]$Policy.evaluation.go_threshold -and
    $ValidationScore -ge [double]$Policy.evaluation.minimum_validation_score
) {
    "go"
}
elseif ($Composite -ge [double]$Policy.evaluation.conditional_threshold) {
    "conditional"
}
else {
    "no_go"
}

$Reasoning = New-Object System.Collections.Generic.List[string]
$Reasoning.Add("Opportunity score: $([math]::Round($OpportunityScore,2))")
$Reasoning.Add("Validation score: $([math]::Round($ValidationScore,2))")
$Reasoning.Add("Budget efficiency score: $([math]::Round($BudgetScore,2))")
$Reasoning.Add("Composite venture score: $([math]::Round($Composite,2))")

$Id = New-AIOfficeVenturePlanningId -Prefix "BIZEVAL"

$Record = [ordered]@{
    evaluation_id = $Id
    idea_id = $IdeaId
    idea_name = [string]$Idea.name
    opportunity_score = [math]::Round($OpportunityScore,2)
    validation_score = [math]::Round($ValidationScore,2)
    budget_score = [math]::Round($BudgetScore,2)
    composite_score = [math]::Round($Composite,2)
    recommendation = $Recommendation
    reasoning = @($Reasoning | ForEach-Object { $_ })
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\evaluations\$Id.json"

Write-Host "Venture evaluation created: $Id | $Recommendation | score=$($Record.composite_score)" -ForegroundColor Green
return [pscustomobject]$Record
