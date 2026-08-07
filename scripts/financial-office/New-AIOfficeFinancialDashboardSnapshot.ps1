param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Index = & "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1"

function Read-RecentFinancialRecords {
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [Parameter(Mandatory=$true)][string]$Filter,
        [int]$Limit = 10
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Directory `
            -Filter $Filter `
            -File `
            -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $Limit |
        ForEach-Object {
            try {
                Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
            }
            catch {
            }
        } |
        Where-Object { $null -ne $_ }
    )
}

$Bills = Read-RecentFinancialRecords `
    -Directory "E:\AI\AI-Office\workspace\financial-office\bills" `
    -Filter "FINBILL-*.json" `
    -Limit 12

$Debts = Read-RecentFinancialRecords `
    -Directory "E:\AI\AI-Office\workspace\financial-office\debts" `
    -Filter "FINDEBT-*.json" `
    -Limit 12

$Goals = Read-RecentFinancialRecords `
    -Directory "E:\AI\AI-Office\workspace\financial-office\goals" `
    -Filter "FINGOAL-*.json" `
    -Limit 12

$SideHustles = Read-RecentFinancialRecords `
    -Directory "E:\AI\AI-Office\workspace\financial-office\side-hustles" `
    -Filter "FINSH-*.json" `
    -Limit 12

$Recommendations = Read-RecentFinancialRecords `
    -Directory "E:\AI\AI-Office\workspace\financial-office\recommendations" `
    -Filter "FINREC-*.json" `
    -Limit 4

$Forecasts = Read-RecentFinancialRecords `
    -Directory "E:\AI\AI-Office\workspace\financial-office\forecasts" `
    -Filter "FINCF-*.json" `
    -Limit 4

$PaycheckPlans = Read-RecentFinancialRecords `
    -Directory "E:\AI\AI-Office\workspace\financial-office\paycheck-plans" `
    -Filter "FINPAY-*.json" `
    -Limit 4

$GoalProgressPercent = 0.0

if ([double]$Index.total_goal_target -gt 0) {
    $GoalProgressPercent = (
        [double]$Index.total_goal_progress /
        [double]$Index.total_goal_target
    ) * 100.0
}

$Snapshot = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    status = [string]$Index.status
    account_count = [int]$Index.account_count
    transaction_count = [int]$Index.transaction_count
    bill_count = [int]$Index.bill_count
    debt_count = [int]$Index.debt_count
    goal_count = [int]$Index.goal_count
    income_source_count = [int]$Index.income_source_count
    total_liquid_balance = [double]$Index.total_liquid_balance
    total_debt_balance = [double]$Index.total_debt_balance
    total_goal_target = [double]$Index.total_goal_target
    total_goal_progress = [double]$Index.total_goal_progress
    goal_progress_percent = [math]::Round($GoalProgressPercent,1)
    monthly_income = [double]$Index.monthly_income
    monthly_expenses = [double]$Index.monthly_expenses
    monthly_net = [double]$Index.monthly_net
    bills = @(
        $Bills |
        ForEach-Object {
            [ordered]@{
                bill_id = [string]$_.bill_id
                name = [string]$_.name
                amount = [double]$_.amount
                frequency = [string]$_.frequency
                due_rule = [string]$_.due_rule
                category = [string]$_.category
                status = [string]$_.status
                autopay = [bool]$_.autopay
            }
        }
    )
    debts = @(
        $Debts |
        ForEach-Object {
            [ordered]@{
                debt_id = [string]$_.debt_id
                name = [string]$_.name
                balance = [double]$_.balance
                minimum_payment = [double]$_.minimum_payment
                interest_rate = [double]$_.interest_rate
                status = [string]$_.status
            }
        }
    )
    goals = @(
        $Goals |
        ForEach-Object {
            $Pct = 0.0
            if ([double]$_.target_amount -gt 0) {
                $Pct = ([double]$_.current_amount / [double]$_.target_amount) * 100.0
            }

            [ordered]@{
                goal_id = [string]$_.goal_id
                name = [string]$_.name
                goal_type = [string]$_.goal_type
                target_amount = [double]$_.target_amount
                current_amount = [double]$_.current_amount
                progress_percent = [math]::Round($Pct,1)
                target_date = [string]$_.target_date
                priority = [string]$_.priority
                status = [string]$_.status
            }
        }
    )
    side_hustles = @(
        $SideHustles |
        ForEach-Object {
            [ordered]@{
                side_hustle_id = [string]$_.side_hustle_id
                name = [string]$_.name
                gross_revenue = [double]$_.gross_revenue
                expenses = [double]$_.expenses
                net_profit = [double]$_.net_profit
                hourly_rate = [double]$_.hourly_rate
                profit_margin = [double]$_.profit_margin
                created_at = [string]$_.created_at
            }
        }
    )
    latest_recommendations = @(
        $Recommendations |
        ForEach-Object {
            foreach ($Rec in @($_.recommendations)) {
                [ordered]@{
                    recommendation_id = [string]$_.recommendation_id
                    priority = [string]$Rec.priority
                    category = [string]$Rec.category
                    recommendation = [string]$Rec.recommendation
                    generated_at = [string]$_.generated_at
                }
            }
        } |
        Select-Object -First 10
    )
    latest_forecast = if (@($Forecasts).Count -gt 0) {
        [ordered]@{
            forecast_id = [string]$Forecasts[0].forecast_id
            opening_balance = [double]$Forecasts[0].opening_balance
            projected_closing_balance = [double]$Forecasts[0].projected_closing_balance
            start_date = [string]$Forecasts[0].start_date
            end_date = [string]$Forecasts[0].end_date
        }
    } else {
        $null
    }
    latest_paycheck_plan = if (@($PaycheckPlans).Count -gt 0) {
        [ordered]@{
            paycheck_plan_id = [string]$PaycheckPlans[0].paycheck_plan_id
            pay_date = [string]$PaycheckPlans[0].pay_date
            net_pay = [double]$PaycheckPlans[0].net_pay
            remaining_cash = [double]$PaycheckPlans[0].remaining_cash
            allocation_count = @($PaycheckPlans[0].allocations).Count
        }
    } else {
        $null
    }
}

$OutputPath = "E:\AI\AI-Office\dashboard\public\financial-office-status.json"

$Snapshot |
    ConvertTo-Json -Depth 80 |
    Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host "Financial Office dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
