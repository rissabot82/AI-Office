param(
    [Parameter(Mandatory=$true)][string]$PayDate,
    [Parameter(Mandatory=$true)][double]$NetPay,
    [double]$ReservePercent = 5.0
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialPlanning.Common.ps1"

[datetime]$ParsedPayDate = $PayDate
$Bills = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\bills" `
    -Filter "FINBILL-*.json"

$Debts = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\debts" `
    -Filter "FINDEBT-*.json"

$Goals = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\goals" `
    -Filter "FINGOAL-*.json"

$PlanId = New-AIOfficeFinancialPlanningId -Prefix "FINPAY"
$Available = [math]::Round($NetPay,2)
$Allocations = New-Object System.Collections.Generic.List[object]

$Reserve = [math]::Round(($NetPay * ($ReservePercent / 100.0)),2)
if ($Reserve -gt 0 -and $Reserve -le $Available) {
    $Allocations.Add([pscustomobject]@{
        allocation_type = "reserve"
        name = "Cash reserve"
        amount = $Reserve
    })
    $Available -= $Reserve
}

foreach ($Bill in @($Bills | Where-Object { [string]$_.status -eq "active" } | Sort-Object amount)) {
    $Amount = [double]$Bill.amount
    if ($Amount -le 0 -or $Amount -gt $Available) { continue }

    $Allocations.Add([pscustomobject]@{
        allocation_type = "bill"
        name = [string]$Bill.name
        reference_id = [string]$Bill.bill_id
        amount = [math]::Round($Amount,2)
    })
    $Available -= $Amount
}

foreach ($Debt in @($Debts | Where-Object { [string]$_.status -eq "active" } | Sort-Object minimum_payment)) {
    $Amount = [double]$Debt.minimum_payment
    if ($Amount -le 0 -or $Amount -gt $Available) { continue }

    $Allocations.Add([pscustomobject]@{
        allocation_type = "debt_minimum"
        name = [string]$Debt.name
        reference_id = [string]$Debt.debt_id
        amount = [math]::Round($Amount,2)
    })
    $Available -= $Amount
}

foreach ($Goal in @($Goals | Where-Object { [string]$_.status -eq "active" } | Sort-Object priority)) {
    if ($Available -le 0) { break }

    $Remaining = [math]::Max(0.0, ([double]$Goal.target_amount - [double]$Goal.current_amount))
    if ($Remaining -le 0) { continue }

    $Contribution = [math]::Min($Remaining, $Available)

    $Allocations.Add([pscustomobject]@{
        allocation_type = "goal"
        name = [string]$Goal.name
        reference_id = [string]$Goal.goal_id
        amount = [math]::Round($Contribution,2)
    })

    $Available -= $Contribution
}

$Record = [ordered]@{
    paycheck_plan_id = $PlanId
    pay_date = $ParsedPayDate.ToString("yyyy-MM-dd")
    net_pay = [math]::Round($NetPay,2)
    reserve_percent = $ReservePercent
    allocations = @($Allocations | ForEach-Object { $_ })
    remaining_cash = [math]::Round($Available,2)
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\paycheck-plans\$PlanId.json"

Write-Host "Paycheck plan created: $PlanId | remaining=$($Record.remaining_cash)" -ForegroundColor Green
return [pscustomobject]$Record
