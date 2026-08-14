param(
    [Parameter(Mandatory=$true)][double]$EstimatedRequestCostUsd
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\live-escalation-policy.json" `
    -Raw | ConvertFrom-Json

$Usage = & "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeExternalUsage.ps1"

$Reasons = New-Object System.Collections.Generic.List[string]

if ($EstimatedRequestCostUsd -lt 0) {
    $Reasons.Add("Estimated request cost is invalid.")
}

if ($EstimatedRequestCostUsd -gt [double]$Policy.cost_guardrails.max_estimated_request_cost_usd) {
    $Reasons.Add("Estimated request cost exceeds the per-request limit.")
}

if (($Usage.daily_cost_usd + $EstimatedRequestCostUsd) -gt [double]$Policy.cost_guardrails.daily_budget_usd) {
    $Reasons.Add("Estimated request would exceed the daily budget.")
}

if (($Usage.monthly_cost_usd + $EstimatedRequestCostUsd) -gt [double]$Policy.cost_guardrails.monthly_budget_usd) {
    $Reasons.Add("Estimated request would exceed the monthly budget.")
}

return [pscustomobject]@{
    allowed = ($Reasons.Count -eq 0)
    reasons = $Reasons.ToArray()
    estimated_request_cost_usd = $EstimatedRequestCostUsd
    daily_cost_after_usd = [math]::Round(($Usage.daily_cost_usd + $EstimatedRequestCostUsd),6)
    monthly_cost_after_usd = [math]::Round(($Usage.monthly_cost_usd + $EstimatedRequestCostUsd),6)
}
