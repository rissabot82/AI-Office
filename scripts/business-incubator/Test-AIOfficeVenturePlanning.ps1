param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.8 Part B Validation and Venture Planning..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\business-incubator\venture-planning-policy.json",
    ".\config\business-incubator\venture-evaluation-schema.json",
    ".\config\business-incubator\market-analysis-schema.json",
    ".\config\business-incubator\validation-result-schema.json",
    ".\config\business-incubator\launch-budget-analysis-schema.json",
    ".\config\business-incubator\portfolio-priority-schema.json",
    ".\workspace\templates\business-venture-evaluation-template.json",
    ".\workspace\templates\business-market-analysis-template.json",
    ".\workspace\templates\business-validation-result-template.json",
    ".\workspace\templates\business-launch-budget-analysis-template.json",
    ".\workspace\templates\business-portfolio-priority-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\business-incubator\AIOfficeVenturePlanning.Common.ps1",
    ".\scripts\business-incubator\New-AIOfficeMarketAnalysis.ps1",
    ".\scripts\business-incubator\Set-AIOfficeValidationResult.ps1",
    ".\scripts\business-incubator\New-AIOfficeLaunchBudgetAnalysis.ps1",
    ".\scripts\business-incubator\New-AIOfficeVentureEvaluation.ps1",
    ".\scripts\business-incubator\New-AIOfficeVenturePortfolioPriority.ps1",
    ".\scripts\business-incubator\Test-AIOfficeVenturePlanning.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$Created = New-Object System.Collections.Generic.List[object]

try {
    $Idea = & ".\scripts\business-incubator\New-AIOfficeBusinessIdea.ps1" `
        -Name "Certification Venture B" `
        -OpportunityType "service" `
        -Summary "Certification venture for Part B testing." `
        -TargetCustomer "Small businesses" `
        -Problem "Manual reporting burden" `
        -Solution "Automated reporting" `
        -RevenueModel "Subscription" `
        -EstimatedStartupCost 600 `
        -EstimatedMonthlyRevenue 2500

    $Created.Add([pscustomobject]@{ type="idea"; id=[string]$Idea.idea_id })

    $Score = & ".\scripts\business-incubator\New-AIOfficeOpportunityScore.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -DimensionsJson '[{"name":"market_demand","score":90,"weight":2},{"name":"profit_potential","score":90,"weight":2},{"name":"automation_potential","score":95,"weight":2},{"name":"time_to_launch","score":80,"weight":1}]'

    $Created.Add([pscustomobject]@{ type="score"; id=[string]$Score.score_id })

    $Market = & ".\scripts\business-incubator\New-AIOfficeMarketAnalysis.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -MarketSummary "Certification market shows viable demand." `
        -CompetitorsJson '["Competitor A","Competitor B"]' `
        -PricingObservationsJson '["$199/mo","$299/mo"]' `
        -DemandSignalsJson '["manual reporting pain","automation demand"]' `
        -CustomerPainsJson '["time","data consolidation"]'

    $Created.Add([pscustomobject]@{ type="market"; id=[string]$Market.market_analysis_id })

    if (@($Market.competitors).Count -ne 2) {
        throw "Market analysis did not preserve competitor records."
    }

    Write-Host "[MARKET OK] $($Market.market_analysis_id)" -ForegroundColor Green

    $Experiment = & ".\scripts\business-incubator\New-AIOfficeValidationExperiment.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -Method "landing_page" `
        -Hypothesis "Qualified prospects will request a demo." `
        -SuccessMetric "10 qualified leads."

    $Created.Add([pscustomobject]@{ type="validation"; id=[string]$Experiment.experiment_id })

    $Validation = & ".\scripts\business-incubator\Set-AIOfficeValidationResult.ps1" `
        -ExperimentId ([string]$Experiment.experiment_id) `
        -Score 85 `
        -MetricsJson '{"qualified_leads":14,"conversion_rate":0.12}' `
        -Conclusion "Validation target exceeded."

    $Created.Add([pscustomobject]@{ type="validation-result"; id=[string]$Validation.validation_result_id })

    if ([string]$Validation.status -ne "validated") {
        throw "Validation result did not reach validated status."
    }

    Write-Host "[VALIDATION OK] $($Validation.validation_result_id)" -ForegroundColor Green

    $Budget = & ".\scripts\business-incubator\New-AIOfficeLaunchBudgetAnalysis.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -LaunchBudget 1200 `
        -ExpectedMonthlyRevenue 2500 `
        -ExpectedMonthlyExpenses 500

    $Created.Add([pscustomobject]@{ type="budget"; id=[string]$Budget.budget_analysis_id })

    if ([double]$Budget.expected_monthly_profit -ne 2000) {
        throw "Launch budget profitability calculation failed."
    }

    Write-Host "[BUDGET OK] $($Budget.budget_analysis_id)" -ForegroundColor Green

    $Evaluation = & ".\scripts\business-incubator\New-AIOfficeVentureEvaluation.ps1" `
        -IdeaId ([string]$Idea.idea_id)

    $Created.Add([pscustomobject]@{ type="evaluation"; id=[string]$Evaluation.evaluation_id })

    if ([string]$Evaluation.recommendation -ne "go") {
        throw "Certification venture did not receive expected GO recommendation."
    }

    Write-Host "[EVALUATION OK] $($Evaluation.evaluation_id) | go" -ForegroundColor Green

    $Portfolio = & ".\scripts\business-incubator\New-AIOfficeVenturePortfolioPriority.ps1"

    $Created.Add([pscustomobject]@{ type="portfolio"; id=[string]$Portfolio.portfolio_id })

    $Match = @(
        $Portfolio.rankings |
        Where-Object { [string]$_.idea_id -eq [string]$Idea.idea_id }
    )

    if ($Match.Count -lt 1) {
        throw "Portfolio prioritization did not include certification venture."
    }

    Write-Host "[PORTFOLIO OK] $($Portfolio.portfolio_id)" -ForegroundColor Green
}
catch {
    Write-Host "[VENTURE ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "idea" { $Path = ".\workspace\business-incubator\ideas\$($Item.id).json" }
        "score" { $Path = ".\workspace\business-incubator\scores\$($Item.id).json" }
        "market" { $Path = ".\workspace\business-incubator\market-analysis\$($Item.id).json" }
        "validation" { $Path = ".\workspace\business-incubator\validation\$($Item.id).json" }
        "validation-result" { $Path = ".\workspace\business-incubator\validation-results\$($Item.id).json" }
        "budget" { $Path = ".\workspace\business-incubator\budget-analysis\$($Item.id).json" }
        "evaluation" { $Path = ".\workspace\business-incubator\evaluations\$($Item.id).json" }
        "portfolio" { $Path = ".\workspace\business-incubator\portfolio\$($Item.id).json" }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Validation and Venture Planning error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.8 Part B Validation and Venture Planning checks passed." -ForegroundColor Green
