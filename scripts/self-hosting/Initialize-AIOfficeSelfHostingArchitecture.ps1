param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$ExistingProviders = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\providers" `
    -Filter "SHPROV-*.json"

$Ollama = @(
    $ExistingProviders |
    Where-Object { [string]$_.provider_type -eq "ollama" }
)

if ($Ollama.Count -eq 0) {
    $Provider = & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeSelfHostedProvider.ps1" `
        -Name "Local Ollama" `
        -ProviderType "ollama" `
        -Endpoint "http://127.0.0.1:11434" `
        -Status "configured" `
        -MetadataJson '{"purpose":"primary_local_inference"}'
}
else {
    $Provider = $Ollama[0]
    Write-Host "Local Ollama provider already configured: $($Provider.provider_id)" -ForegroundColor Yellow
}

$ExistingRules = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\routing-rules" `
    -Filter "SHROUTE-*.json"

if (@($ExistingRules | Where-Object { [string]$_.name -eq "Private Context Local Preferred" }).Count -eq 0) {
    & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeModelRoutingRule.ps1" `
        -Name "Private Context Local Preferred" `
        -Priority 10 `
        -ConditionsJson '{"sensitive_context":true}' `
        -DestinationJson ('{"mode":"local_preferred","provider_id":"' + [string]$Provider.provider_id + '"}') |
        Out-Null
}

if (@($ExistingRules | Where-Object { [string]$_.name -eq "Complex Reasoning Cloud Fallback" }).Count -eq 0) {
    & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeModelRoutingRule.ps1" `
        -Name "Complex Reasoning Cloud Fallback" `
        -Priority 50 `
        -ConditionsJson '{"complexity":"high"}' `
        -DestinationJson '{"mode":"balanced","allow_cloud_fallback":true}' |
        Out-Null
}

& "E:\AI\AI-Office\scripts\self-hosting\Get-AIOfficeHardwareProfile.ps1" -Save | Out-Null
& "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null

Write-Host "Self-hosting architecture initialized." -ForegroundColor Green
