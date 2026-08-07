param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$AccountType,
    [double]$CurrentBalance = 0.0,
    [string]$Institution = "",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Policy = Get-AIOfficeFinancialPolicy

if (@($Policy.account_types) -notcontains $AccountType) {
    throw "Unsupported account type: $AccountType"
}

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeFinancialId -Prefix "FINACC"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    account_id = $Id
    name = $Name
    account_type = $AccountType
    institution = $Institution
    status = "active"
    current_balance = [math]::Round($CurrentBalance,2)
    currency = [string]$Policy.currency
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\accounts\$Id.json"

& "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

Write-Host "Financial account created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
