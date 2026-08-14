param()

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\live-escalation-policy.json" `
    -Raw | ConvertFrom-Json

$Ledger = Join-Path "E:\AI\AI-Office" ([string]$Policy.usage_ledger)

$Today = (Get-Date).Date
$MonthStart = Get-Date -Day 1
$Daily = 0.0
$Monthly = 0.0
$RequestsToday = 0
$RequestsMonth = 0

if (Test-Path -LiteralPath $Ledger -PathType Leaf) {
    foreach ($Line in Get-Content -LiteralPath $Ledger) {
        if ([string]::IsNullOrWhiteSpace($Line)) { continue }
        try {
            $Item = $Line | ConvertFrom-Json
            $When = [datetime]$Item.created_at
            $Cost = [double]$Item.estimated_cost_usd

            if ($When -ge $MonthStart) {
                $Monthly += $Cost
                $RequestsMonth++
            }

            if ($When.Date -eq $Today) {
                $Daily += $Cost
                $RequestsToday++
            }
        }
        catch {}
    }
}

return [pscustomobject]@{
    daily_cost_usd = [math]::Round($Daily,6)
    monthly_cost_usd = [math]::Round($Monthly,6)
    requests_today = $RequestsToday
    requests_month = $RequestsMonth
    daily_budget_usd = [double]$Policy.cost_guardrails.daily_budget_usd
    monthly_budget_usd = [double]$Policy.cost_guardrails.monthly_budget_usd
    checked_at = (Get-Date).ToString("o")
}
