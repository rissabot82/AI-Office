param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.7 Part A Personal Financial Office Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\financial-office\financial-policy.json",
    ".\config\financial-office\account-schema.json",
    ".\config\financial-office\transaction-schema.json",
    ".\config\financial-office\bill-schema.json",
    ".\config\financial-office\debt-schema.json",
    ".\config\financial-office\goal-schema.json",
    ".\config\financial-office\income-source-schema.json",
    ".\workspace\financial-office\indexes\financial-index.json",
    ".\workspace\templates\financial-account-template.json",
    ".\workspace\templates\financial-transaction-template.json",
    ".\workspace\templates\financial-bill-template.json",
    ".\workspace\templates\financial-debt-template.json",
    ".\workspace\templates\financial-goal-template.json",
    ".\workspace\templates\financial-income-source-template.json"
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
    ".\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1",
    ".\scripts\financial-office\New-AIOfficeFinancialAccount.ps1",
    ".\scripts\financial-office\New-AIOfficeFinancialTransaction.ps1",
    ".\scripts\financial-office\New-AIOfficeFinancialBill.ps1",
    ".\scripts\financial-office\New-AIOfficeFinancialDebt.ps1",
    ".\scripts\financial-office\New-AIOfficeFinancialGoal.ps1",
    ".\scripts\financial-office\New-AIOfficeIncomeSource.ps1",
    ".\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1",
    ".\scripts\financial-office\Show-AIOfficeFinancialStatus.ps1",
    ".\scripts\financial-office\Test-AIOfficeFinancialOfficeArchitecture.ps1"
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
        -Name "Certification Checking" `
        -AccountType "checking" `
        -CurrentBalance 1000 `
        -Institution "Certification Bank"

    $Created.Add([pscustomobject]@{ type="account"; id=[string]$Account.account_id })

    $TxnIncome = & ".\scripts\financial-office\New-AIOfficeFinancialTransaction.ps1" `
        -AccountId ([string]$Account.account_id) `
        -TransactionType "income" `
        -Amount 500 `
        -Date (Get-Date).ToString("yyyy-MM-dd") `
        -Category "other" `
        -Description "Certification income"

    $Created.Add([pscustomobject]@{ type="transaction"; id=[string]$TxnIncome.transaction_id })

    $TxnExpense = & ".\scripts\financial-office\New-AIOfficeFinancialTransaction.ps1" `
        -AccountId ([string]$Account.account_id) `
        -TransactionType "expense" `
        -Amount 125 `
        -Date (Get-Date).ToString("yyyy-MM-dd") `
        -Category "food" `
        -Description "Certification expense"

    $Created.Add([pscustomobject]@{ type="transaction"; id=[string]$TxnExpense.transaction_id })

    $Bill = & ".\scripts\financial-office\New-AIOfficeFinancialBill.ps1" `
        -Name "Certification Bill" `
        -Amount 75 `
        -Frequency "monthly" `
        -DueRule "15th" `
        -Category "utilities"

    $Created.Add([pscustomobject]@{ type="bill"; id=[string]$Bill.bill_id })

    $Debt = & ".\scripts\financial-office\New-AIOfficeFinancialDebt.ps1" `
        -Name "Certification Debt" `
        -Balance 2000 `
        -MinimumPayment 100 `
        -InterestRate 9.99 `
        -DueRule "20th"

    $Created.Add([pscustomobject]@{ type="debt"; id=[string]$Debt.debt_id })

    $Goal = & ".\scripts\financial-office\New-AIOfficeFinancialGoal.ps1" `
        -Name "Certification Emergency Fund" `
        -GoalType "emergency_fund" `
        -TargetAmount 3000 `
        -CurrentAmount 500 `
        -Priority "high"

    $Created.Add([pscustomobject]@{ type="goal"; id=[string]$Goal.goal_id })

    $IncomeSource = & ".\scripts\financial-office\New-AIOfficeIncomeSource.ps1" `
        -Name "Certification Salary" `
        -SourceType "salary" `
        -ExpectedAmount 2500 `
        -Frequency "monthly"

    $Created.Add([pscustomobject]@{ type="income"; id=[string]$IncomeSource.income_source_id })

    $Index = & ".\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1"

    if (
        [int]$Index.account_count -lt 1 -or
        [int]$Index.transaction_count -lt 2 -or
        [int]$Index.bill_count -lt 1 -or
        [int]$Index.debt_count -lt 1 -or
        [int]$Index.goal_count -lt 1 -or
        [int]$Index.income_source_count -lt 1
    ) {
        throw "Financial index did not contain certification records."
    }

    if ([double]$Index.monthly_income -lt 500) {
        throw "Monthly income aggregation failed."
    }

    if ([double]$Index.monthly_expenses -lt 125) {
        throw "Monthly expense aggregation failed."
    }

    Write-Host "[ACCOUNT OK] $($Account.account_id)" -ForegroundColor Green
    Write-Host "[TRANSACTION OK] 2 transactions" -ForegroundColor Green
    Write-Host "[BILL OK] $($Bill.bill_id)" -ForegroundColor Green
    Write-Host "[DEBT OK] $($Debt.debt_id)" -ForegroundColor Green
    Write-Host "[GOAL OK] $($Goal.goal_id)" -ForegroundColor Green
    Write-Host "[INCOME OK] $($IncomeSource.income_source_id)" -ForegroundColor Green
    Write-Host "[INDEX OK] Financial aggregation passed." -ForegroundColor Green
}
catch {
    Write-Host "[FINANCIAL ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "account" {
            $Path = ".\workspace\financial-office\accounts\$($Item.id).json"
        }
        "transaction" {
            $Path = ".\workspace\financial-office\transactions\$($Item.id).json"
        }
        "bill" {
            $Path = ".\workspace\financial-office\bills\$($Item.id).json"
        }
        "debt" {
            $Path = ".\workspace\financial-office\debts\$($Item.id).json"
        }
        "goal" {
            $Path = ".\workspace\financial-office\goals\$($Item.id).json"
        }
        "income" {
            $Path = ".\workspace\financial-office\income-sources\$($Item.id).json"
        }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Personal Financial Office architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.7 Part A Personal Financial Office Architecture checks passed." -ForegroundColor Green
