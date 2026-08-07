param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][double]$Balance,
    [double]$MinimumPayment = 0.0,
    [double]$InterestRate = 0.0,
    [string]$DueRule = ""
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Id = New-AIOfficeFinancialId -Prefix "FINDEBT"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    debt_id = $Id
    name = $Name
    balance = [math]::Round([math]::Abs($Balance),2)
    minimum_payment = [math]::Round([math]::Abs($MinimumPayment),2)
    interest_rate = [math]::Round([math]::Abs($InterestRate),4)
    due_rule = $DueRule
    status = "active"
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\debts\$Id.json"

& "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

Write-Host "Debt created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
