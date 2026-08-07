param()

$ErrorActionPreference = "Stop"

$Index = & "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE PERSONAL FINANCIAL OFFICE" -ForegroundColor Cyan
Write-Host ("=" * 68)
Write-Host ("Accounts             : " + [string]$Index.account_count)
Write-Host ("Transactions         : " + [string]$Index.transaction_count)
Write-Host ("Bills                : " + [string]$Index.bill_count)
Write-Host ("Debts                : " + [string]$Index.debt_count)
Write-Host ("Goals                : " + [string]$Index.goal_count)
Write-Host ("Income Sources       : " + [string]$Index.income_source_count)
Write-Host ("Liquid Balance       : $" + [string]$Index.total_liquid_balance)
Write-Host ("Debt Balance         : $" + [string]$Index.total_debt_balance)
Write-Host ("Goal Progress        : $" + [string]$Index.total_goal_progress + " / $" + [string]$Index.total_goal_target)
Write-Host ("Monthly Income       : $" + [string]$Index.monthly_income)
Write-Host ("Monthly Expenses     : $" + [string]$Index.monthly_expenses)
Write-Host ("Monthly Net          : $" + [string]$Index.monthly_net)
Write-Host ""

return $Index
