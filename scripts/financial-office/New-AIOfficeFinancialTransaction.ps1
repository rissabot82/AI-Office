param(
    [Parameter(Mandatory=$true)][string]$AccountId,
    [Parameter(Mandatory=$true)][string]$TransactionType,
    [Parameter(Mandatory=$true)][double]$Amount,
    [Parameter(Mandatory=$true)][string]$Date,
    [string]$Category = "other",
    [string]$Description = "",
    [string]$Source = "manual",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Policy = Get-AIOfficeFinancialPolicy

if (@($Policy.transaction_types) -notcontains $TransactionType) {
    throw "Unsupported transaction type: $TransactionType"
}

if (@($Policy.budget_categories) -notcontains $Category) {
    throw "Unsupported budget category: $Category"
}

$AccountPath = "E:\AI\AI-Office\workspace\financial-office\accounts\$AccountId.json"
$Account = Read-AIOfficeFinancialJson -Path $AccountPath

if ($null -eq $Account) {
    throw "Financial account not found: $AccountId"
}

try {
    [datetime]$ParsedDate = $Date
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "Date or MetadataJson is invalid."
}

$Id = New-AIOfficeFinancialId -Prefix "FINTXN"
$Record = [ordered]@{
    transaction_id = $Id
    account_id = $AccountId
    transaction_type = $TransactionType
    amount = [math]::Round([math]::Abs($Amount),2)
    date = $ParsedDate.ToString("yyyy-MM-dd")
    category = $Category
    description = $Description
    source = $Source
    metadata = $Metadata
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\transactions\$Id.json"

& "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

Write-Host "Financial transaction created: $Id | $TransactionType | $($Record.amount)" -ForegroundColor Green
return [pscustomobject]$Record
