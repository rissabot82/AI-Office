param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.7 Part B Planning and Analysis..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\financial-office\planning-policy.json",
    ".\config\financial-office\paycheck-plan-schema.json",
    ".\config\financial-office\cash-flow-schema.json",
    ".\config\financial-office\debt-analysis-schema.json",
    ".\config\financial-office\goal-projection-schema.json",
    ".\config\financial-office\side-hustle-schema.json",
    ".\workspace\templates\financial-paycheck-plan-template.json",
    ".\workspace\templates\financial-cash-flow-template.json",
    ".\workspace\templates\financial-debt-analysis-template.json",
    ".\workspace\templates\financial-goal-projection-template.json",
    ".\workspace\templates\financial-side-hustle-template.json"
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
    ".\scripts\financial-office\AIOfficeFinancialPlanning.Common.ps1",
    ".\scripts\financial-office\New-AIOfficePaycheckPlan.ps1",
    ".\scripts\financial-office\New-AIOfficeCashFlowForecast.ps1",
    ".\scripts\financial-office\New-AIOfficeDebtAnalysis.ps1",
    ".\scripts\financial-office\New-AIOfficeGoalProjection.ps1",
    ".\scripts\financial-office\New-AIOfficeSideHustlePerformance.ps1",
    ".\scripts\financial-office\New-AIOfficeFinancialRecommendations.ps1",
    ".\scripts\financial-office\Test-AIOfficeFinancialPlanning.ps1"
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
    $Account = & ".\scripts\financial-office\New-AIOfficeFinancialAccount.ps1" `
        -Name "Planning Certification Checking" `
        -AccountType "checking" `
        -CurrentBalance 1200

    $Created.Add([pscustomobject]@{ type="account"; id=[string]$Account.account_id })

    $Bill = & ".\scripts\financial-office\New-AIOfficeFinancialBill.ps1" `
        -Name "Planning Certification Rent" `
        -Amount 600 `
        -Frequency "monthly" `
        -DueRule "1st" `
        -Category "housing"

    $Created.Add([pscustomobject]@{ type="bill"; id=[string]$Bill.bill_id })

    $DebtA = & ".\scripts\financial-office\New-AIOfficeFinancialDebt.ps1" `
        -Name "Planning Certification Debt A" `
        -Balance 1500 `
        -MinimumPayment 75 `
        -InterestRate 18.0

    $Created.Add([pscustomobject]@{ type="debt"; id=[string]$DebtA.debt_id })

    $DebtB = & ".\scripts\financial-office\New-AIOfficeFinancialDebt.ps1" `
        -Name "Planning Certification Debt B" `
        -Balance 500 `
        -MinimumPayment 50 `
        -InterestRate 5.0

    $Created.Add([pscustomobject]@{ type="debt"; id=[string]$DebtB.debt_id })

    $Goal = & ".\scripts\financial-office\New-AIOfficeFinancialGoal.ps1" `
        -Name "Planning Certification Goal" `
        -GoalType "emergency_fund" `
        -TargetAmount 3000 `
        -CurrentAmount 600

    $Created.Add([pscustomobject]@{ type="goal"; id=[string]$Goal.goal_id })

    $Income = & ".\scripts\financial-office\New-AIOfficeIncomeSource.ps1" `
        -Name "Planning Certification Income" `
        -SourceType "salary" `
        -ExpectedAmount 2500 `
        -Frequency "monthly"

    $Created.Add([pscustomobject]@{ type="income"; id=[string]$Income.income_source_id })

    $PayPlan = & ".\scripts\financial-office\New-AIOfficePaycheckPlan.ps1" `
        -PayDate (Get-Date).ToString("yyyy-MM-dd") `
        -NetPay 2200 `
        -ReservePercent 5

    $Created.Add([pscustomobject]@{ type="paycheck"; id=[string]$PayPlan.paycheck_plan_id })

    if ([double]$PayPlan.net_pay -ne 2200) {
        throw "Paycheck planner returned an unexpected net pay."
    }

    Write-Host "[PAYCHECK OK] $($PayPlan.paycheck_plan_id)" -ForegroundColor Green

    $Forecast = & ".\scripts\financial-office\New-AIOfficeCashFlowForecast.ps1" `
        -OpeningBalance 1000 `
        -HorizonDays 90

    $Created.Add([pscustomobject]@{ type="forecast"; id=[string]$Forecast.forecast_id })

    if ([double]$Forecast.projected_closing_balance -le 0) {
        throw "Cash-flow forecast returned an unexpected closing balance."
    }

    Write-Host "[FORECAST OK] $($Forecast.forecast_id)" -ForegroundColor Green

    $Avalanche = & ".\scripts\financial-office\New-AIOfficeDebtAnalysis.ps1" `
        -Strategy "avalanche"

    $Created.Add([pscustomobject]@{ type="debt-analysis"; id=[string]$Avalanche.analysis_id })

    if (@($Avalanche.ordered_debts).Count -lt 2) {
        throw "Debt analysis did not include both certification debts."
    }

    if ([string]$Avalanche.ordered_debts[0].name -ne "Planning Certification Debt A") {
        throw "Avalanche ordering did not prioritize the highest interest rate."
    }

    Write-Host "[DEBT OK] Avalanche strategy passed." -ForegroundColor Green

    $Projection = & ".\scripts\financial-office\New-AIOfficeGoalProjection.ps1" `
        -GoalId ([string]$Goal.goal_id) `
        -MonthlyContribution 200

    $Created.Add([pscustomobject]@{ type="goal-projection"; id=[string]$Projection.projection_id })

    if ([int]$Projection.months_to_goal -ne 12) {
        throw "Goal projection expected 12 months."
    }

    Write-Host "[GOAL OK] $($Projection.projection_id)" -ForegroundColor Green

    $SideHustle = & ".\scripts\financial-office\New-AIOfficeSideHustlePerformance.ps1" `
        -Name "Planning Certification Side Hustle" `
        -GrossRevenue 500 `
        -Expenses 100 `
        -Hours 10

    $Created.Add([pscustomobject]@{ type="side-hustle"; id=[string]$SideHustle.side_hustle_id })

    if ([double]$SideHustle.net_profit -ne 400 -or [double]$SideHustle.hourly_rate -ne 40) {
        throw "Side hustle profitability calculation failed."
    }

    Write-Host "[SIDE HUSTLE OK] net=400 | hourly=40" -ForegroundColor Green

    $Recommendations = & ".\scripts\financial-office\New-AIOfficeFinancialRecommendations.ps1"

    $Created.Add([pscustomobject]@{ type="recommendation"; id=[string]$Recommendations.recommendation_id })

    if (@($Recommendations.recommendations).Count -lt 1) {
        throw "Financial recommendation engine returned no recommendations."
    }

    Write-Host "[RECOMMENDATION OK] $(@($Recommendations.recommendations).Count) recommendation(s)" -ForegroundColor Green
}
catch {
    Write-Host "[PLANNING ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "account" { $Path = ".\workspace\financial-office\accounts\$($Item.id).json" }
        "bill" { $Path = ".\workspace\financial-office\bills\$($Item.id).json" }
        "debt" { $Path = ".\workspace\financial-office\debts\$($Item.id).json" }
        "goal" { $Path = ".\workspace\financial-office\goals\$($Item.id).json" }
        "income" { $Path = ".\workspace\financial-office\income-sources\$($Item.id).json" }
        "paycheck" { $Path = ".\workspace\financial-office\paycheck-plans\$($Item.id).json" }
        "forecast" { $Path = ".\workspace\financial-office\forecasts\$($Item.id).json" }
        "debt-analysis" { $Path = ".\workspace\financial-office\debt-analysis\$($Item.id).json" }
        "goal-projection" { $Path = ".\workspace\financial-office\goal-projections\$($Item.id).json" }
        "side-hustle" { $Path = ".\workspace\financial-office\side-hustles\$($Item.id).json" }
        "recommendation" { $Path = ".\workspace\financial-office\recommendations\$($Item.id).json" }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Personal Financial Office planning error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.7 Part B Planning and Analysis checks passed." -ForegroundColor Green
