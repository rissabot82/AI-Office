param(
    [Parameter(Mandatory=$true)][double]$OpeningBalance,
    [int]$HorizonDays = 90
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialPlanning.Common.ps1"

$Start = (Get-Date).Date
$End = $Start.AddDays($HorizonDays)

$Bills = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\bills" `
    -Filter "FINBILL-*.json"

$IncomeSources = Get-AIOfficeFinancialCollection `
    -Directory "E:\AI\AI-Office\workspace\financial-office\income-sources" `
    -Filter "FININC-*.json"

$Entries = New-Object System.Collections.Generic.List[object]
$Balance = [double]$OpeningBalance

foreach ($Income in $IncomeSources | Where-Object { [string]$_.status -eq "active" }) {
    $Amount = [double]$Income.expected_amount
    if ($Amount -le 0) { continue }

    $Entries.Add([pscustomobject]@{
        entry_type = "income"
        name = [string]$Income.name
        amount = [math]::Round($Amount,2)
    })
    $Balance += $Amount
}

foreach ($Bill in $Bills | Where-Object { [string]$_.status -eq "active" }) {
    $Amount = [double]$Bill.amount
    if ($Amount -le 0) { continue }

    $Entries.Add([pscustomobject]@{
        entry_type = "bill"
        name = [string]$Bill.name
        amount = [math]::Round(-1 * $Amount,2)
    })
    $Balance -= $Amount
}

$ForecastId = New-AIOfficeFinancialPlanningId -Prefix "FINCF"

$Record = [ordered]@{
    forecast_id = $ForecastId
    start_date = $Start.ToString("yyyy-MM-dd")
    end_date = $End.ToString("yyyy-MM-dd")
    opening_balance = [math]::Round($OpeningBalance,2)
    projected_closing_balance = [math]::Round($Balance,2)
    entries = @($Entries | ForEach-Object { $_ })
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\forecasts\$ForecastId.json"

Write-Host "Cash-flow forecast created: $ForecastId | closing=$($Record.projected_closing_balance)" -ForegroundColor Green
return [pscustomobject]$Record
