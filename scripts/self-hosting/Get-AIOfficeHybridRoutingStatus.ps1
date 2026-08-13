param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Decisions = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\routing-decisions" `
    -Filter "SHDEC-*.json"

$Results = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\hybrid-results" `
    -Filter "SHHYB-*.json"

$Status = [ordered]@{
    routing_decisions = @($Decisions).Count
    local_decisions = @($Decisions | Where-Object { [string]$_.selected_provider -eq "ollama" }).Count
    cloud_decisions = @($Decisions | Where-Object { [string]$_.selected_provider -eq "openclaw" }).Count
    hybrid_results = @($Results).Count
    fallback_results = @($Results | Where-Object { [bool]$_.fallback_used }).Count
    generated_at = (Get-Date).ToString("o")
}

Write-Host ""
Write-Host "AI OFFICE HYBRID MODEL ROUTING" -ForegroundColor Cyan
Write-Host ("=" * 64)
Write-Host ("Routing Decisions : " + $Status.routing_decisions)
Write-Host ("Local Decisions   : " + $Status.local_decisions)
Write-Host ("Cloud Decisions   : " + $Status.cloud_decisions)
Write-Host ("Hybrid Results    : " + $Status.hybrid_results)
Write-Host ("Fallback Results  : " + $Status.fallback_results)
Write-Host ""

return [pscustomobject]$Status
