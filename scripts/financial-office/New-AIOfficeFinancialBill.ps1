param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][double]$Amount,
    [string]$Frequency = "monthly",
    [string]$DueRule = "",
    [string]$Category = "other",
    [switch]$Autopay
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Id = New-AIOfficeFinancialId -Prefix "FINBILL"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    bill_id = $Id
    name = $Name
    amount = [math]::Round([math]::Abs($Amount),2)
    frequency = $Frequency
    due_rule = $DueRule
    category = $Category
    status = "active"
    autopay = [bool]$Autopay
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\bills\$Id.json"

& "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

Write-Host "Bill created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
