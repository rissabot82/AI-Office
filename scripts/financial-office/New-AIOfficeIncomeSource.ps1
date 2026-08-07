param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$SourceType,
    [double]$ExpectedAmount = 0.0,
    [string]$Frequency = "monthly",
    [string]$NextExpectedDate = "",
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"

$Policy = Get-AIOfficeFinancialPolicy

if (@($Policy.income_sources) -notcontains $SourceType) {
    throw "Unsupported income source type: $SourceType"
}

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeFinancialId -Prefix "FININC"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    income_source_id = $Id
    name = $Name
    source_type = $SourceType
    expected_amount = [math]::Round([math]::Abs($ExpectedAmount),2)
    frequency = $Frequency
    next_expected_date = $NextExpectedDate
    status = "active"
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\income-sources\$Id.json"

& "E:\AI\AI-Office\scripts\financial-office\Update-AIOfficeFinancialIndex.ps1" | Out-Null

Write-Host "Income source created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
