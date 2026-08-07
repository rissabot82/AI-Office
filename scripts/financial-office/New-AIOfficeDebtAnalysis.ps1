param(
    [ValidateSet("snowball","avalanche")]
    [string]$Strategy = "avalanche"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialOffice.Common.ps1"
. "E:\AI\AI-Office\scripts\financial-office\AIOfficeFinancialPlanning.Common.ps1"

$Debts = @(
    Get-AIOfficeFinancialCollection `
        -Directory "E:\AI\AI-Office\workspace\financial-office\debts" `
        -Filter "FINDEBT-*.json" |
    Where-Object { [string]$_.status -eq "active" }
)

if ($Strategy -eq "snowball") {
    $Ordered = @($Debts | Sort-Object balance)
}
else {
    $Ordered = @(
        $Debts |
        Sort-Object @{ Expression = { [double]$_.interest_rate }; Descending = $true },
                    @{ Expression = { [double]$_.balance }; Descending = $false }
    )
}

$Total = 0.0
foreach ($Debt in $Debts) {
    $Total += [double]$Debt.balance
}

$AnalysisId = New-AIOfficeFinancialPlanningId -Prefix "FINDA"

$Record = [ordered]@{
    analysis_id = $AnalysisId
    strategy = $Strategy
    total_debt = [math]::Round($Total,2)
    ordered_debts = @(
        $Ordered |
        ForEach-Object {
            [ordered]@{
                debt_id = [string]$_.debt_id
                name = [string]$_.name
                balance = [double]$_.balance
                minimum_payment = [double]$_.minimum_payment
                interest_rate = [double]$_.interest_rate
            }
        }
    )
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeFinancialJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\financial-office\debt-analysis\$AnalysisId.json"

Write-Host "Debt analysis created: $AnalysisId | $Strategy | total=$($Record.total_debt)" -ForegroundColor Green
return [pscustomobject]$Record
