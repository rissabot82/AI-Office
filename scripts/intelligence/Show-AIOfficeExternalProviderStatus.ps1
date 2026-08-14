param()

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\external-provider-policy.json" `
    -Raw | ConvertFrom-Json

$Providers = @(& "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeExternalProviderStatus.ps1")

Write-Host ""
Write-Host "AI OFFICE EXTERNAL INTELLIGENCE PROVIDERS" -ForegroundColor Cyan
Write-Host "========================================="
Write-Host ("Architecture enabled : " + [string]$Policy.enabled)
Write-Host ("Local first          : " + [string]$Policy.local_first)
Write-Host ("Paid inference       : " + [string]$Policy.automatic_paid_inference)
Write-Host ("Daily budget         : $" + [string]$Policy.guardrails.daily_budget_usd)
Write-Host ("Monthly budget       : $" + [string]$Policy.guardrails.monthly_budget_usd)
Write-Host ""

foreach ($Provider in $Providers) {
    Write-Host ($Provider.provider.ToUpperInvariant()) -ForegroundColor Yellow
    Write-Host ("  Supported             : " + [string]$Provider.supported)
    Write-Host ("  Enabled               : " + [string]$Provider.enabled)
    Write-Host ("  Credential configured : " + [string]$Provider.credential_configured)
    Write-Host ("  Model configured      : " + [string]$Provider.model_configured)
    Write-Host ("  Activation ready      : " + [string]$Provider.activation_ready)
}

return $Providers
