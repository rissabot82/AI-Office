param()

$ErrorActionPreference = "Stop"

$Path = "E:\AI\AI-Office\config\intelligence\live-escalation-policy.json"
$Policy = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json

$EnvironmentName = [string]$Policy.credential_environment_variable
$Credential = [Environment]::GetEnvironmentVariable($EnvironmentName,"Process")
if ([string]::IsNullOrWhiteSpace($Credential)) {
    $Credential = [Environment]::GetEnvironmentVariable($EnvironmentName,"User")
}
if ([string]::IsNullOrWhiteSpace($Credential)) {
    throw "$EnvironmentName is not configured. Live paid escalation was NOT enabled."
}

$Policy.enabled = $true
$Policy | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding UTF8

Write-Host "AI Office live external escalation ENABLED." -ForegroundColor Green
Write-Host "Provider: OpenAI | Model: $($Policy.model)" -ForegroundColor Cyan
Write-Host "Daily budget: `$$($Policy.cost_guardrails.daily_budget_usd) | Monthly budget: `$$($Policy.cost_guardrails.monthly_budget_usd)" -ForegroundColor Cyan
