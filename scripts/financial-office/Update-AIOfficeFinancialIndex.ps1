param()

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Accounts = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\accounts" `
    -Filter "FINACC-*.json"

$Transactions = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\transactions" `
    -Filter "FINTXN-*.json"

$Bills = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\bills" `
    -Filter "FINBILL-*.json"

$Debts = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\debts" `
    -Filter "FINDEBT-*.json"

$Goals = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\goals" `
    -Filter "FINGOAL-*.json"

$IncomeSources = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\income-sources" `
    -Filter "FININC-*.json"

$LiquidAccountTypes = @("checking","savings","cash")

$TotalLiquid = 0.0
foreach ($Account in $Accounts) {
    if (@($LiquidAccountTypes) -contains [string]$Account.account_type) {
        $TotalLiquid += [double]$Account.current_balance
    }
}

$TotalDebt = 0.0
foreach ($Debt in $Debts) {
    if ([string]$Debt.status -eq "active") {
        $TotalDebt += [double]$Debt.balance
    }
}

$GoalTarget = 0.0
$GoalProgress = 0.0
foreach ($Goal in $Goals) {
    if ([string]$Goal.status -eq "active") {
        $GoalTarget += [double]$Goal.target_amount
        $GoalProgress += [double]$Goal.current_amount
    }
}

$CurrentMonth = (Get-Date).ToString("yyyy-MM")
$MonthlyIncome = 0.0
$MonthlyExpenses = 0.0

foreach ($Txn in $Transactions) {
    if ([string]$Txn.date -notlike "$CurrentMonth*") {
        continue
    }

    if ([string]$Txn.transaction_type -eq "income") {
        $MonthlyIncome += [double]$Txn.amount
    }
    elseif (
        [string]$Txn.transaction_type -eq "expense" -or
        [string]$Txn.transaction_type -eq "debt_payment"
    ) {
        $MonthlyExpenses += [double]$Txn.amount
    }
}

$Index = [ordered]@{
    version = "1.7.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    account_count = @($Accounts).Count
    transaction_count = @($Transactions).Count
    bill_count = @($Bills).Count
    debt_count = @($Debts).Count
    goal_count = @($Goals).Count
    income_source_count = @($IncomeSources).Count
    total_liquid_balance = [math]::Round($TotalLiquid,2)
    total_debt_balance = [math]::Round($TotalDebt,2)
    total_goal_target = [math]::Round($GoalTarget,2)
    total_goal_progress = [math]::Round($GoalProgress,2)
    monthly_income = [math]::Round($MonthlyIncome,2)
    monthly_expenses = [math]::Round($MonthlyExpenses,2)
    monthly_net = [math]::Round(($MonthlyIncome - $MonthlyExpenses),2)
}

Write-AIOfficeFinancialJson `
    -Value $Index `
    -Path "E:\AI\AI-Office\workspace\financial-office\indexes\financial-index.json"

Write-Host "Financial index updated: $($Index.account_count) accounts | $($Index.transaction_count) transactions | $($Index.debt_count) debts | $($Index.goal_count) goals" -ForegroundColor Green

return [pscustomobject]$Index
