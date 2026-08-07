param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][double]$GrossRevenue,
    [double]$Expenses = 0.0,
    [double]$Hours = 0.0
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialPlanning.Common.ps1"

$Net = $GrossRevenue - $Expenses
$Hourly = if ($Hours -gt 0) { $Net / $Hours } else { 0.0 }
$Margin = if ($GrossRevenue -gt 0) { ($Net / $GrossRevenue) * 100.0 } else { 0.0 }

$Id = New-AIOfficeFinancialPlanningId -Prefix "FINSH"

$Record = [ordered]@{
    side_hustle_id = $Id
    name = $Name
    gross_revenue = [math]::Round($GrossRevenue,2)
    expenses = [math]::Round($Expenses,2)
    hours = [math]::Round($Hours,2)
    net_profit = [math]::Round($Net,2)
    hourly_rate = [math]::Round($Hourly,2)
    profit_margin = [math]::Round($Margin,2)
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\side-hustles\$Id.json"

Write-Host "Side hustle performance recorded: $Id | net=$($Record.net_profit) | hourly=$($Record.hourly_rate)" -ForegroundColor Green
return [pscustomobject]$Record
