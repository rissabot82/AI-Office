param()

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Providers = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\providers" `
    -Filter "SHPROV-*.json"

$Models = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\models" `
    -Filter "SHMODEL-*.json"

$Rules = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\routing-rules" `
    -Filter "SHROUTE-*.json"

$Hardware = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\hardware" `
    -Filter "SHHW-*.json"

$Index = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    provider_count = @($Providers).Count
    connected_provider_count = @(
        $Providers | Where-Object { [string]$_.status -eq "connected" }
    ).Count
    model_count = @($Models).Count
    ready_model_count = @(
        $Models | Where-Object { [string]$_.status -eq "ready" }
    ).Count
    routing_rule_count = @($Rules).Count
    hardware_profile_count = @($Hardware).Count
}

Write-AIOfficeSelfHostingJson `
    -Value $Index `
    -Path "E:\AI\AI-Office\workspace\self-hosting\indexes\self-hosting-index.json"

Write-Host (
    "Self-hosting index updated: " +
    $Index.provider_count + " providers | " +
    $Index.model_count + " models | " +
    $Index.routing_rule_count + " routes | " +
    $Index.hardware_profile_count + " hardware profiles"
) -ForegroundColor Green

return [pscustomobject]$Index
