param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$IndexPath = "E:\AI\AI-Office\workspace\self-hosting\indexes\self-hosting-index.json"

& "E:\AI\AI-Office\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1" | Out-Null
$Index = Read-AIOfficeSelfHostingJson -Path $IndexPath

if ($null -eq $Index) { throw "Self-hosting index unavailable." }

$Health = Get-AIOfficeSelfHostingCollection -Directory "E:\AI\AI-Office\workspace\self-hosting\health" -Filter "SHHEALTH-*.json"
$Inference = Get-AIOfficeSelfHostingCollection -Directory "E:\AI\AI-Office\workspace\self-hosting\inference-results" -Filter "SHINF-*.json"
$Hardware = Get-AIOfficeSelfHostingCollection -Directory "E:\AI\AI-Office\workspace\self-hosting\hardware" -Filter "SHHW-*.json"

$LatestHealth = @($Health | Sort-Object { [string]$_.checked_at } -Descending | Select-Object -First 1)
$LatestHardware = @($Hardware | Sort-Object { [string]$_.captured_at } -Descending | Select-Object -First 1)

$RecentInference = @(
    $Inference |
    Sort-Object { [string]$_.created_at } -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        [ordered]@{
            inference_id = [string]$_.inference_id
            model = [string]$_.model
            status = [string]$_.status
            elapsed_ms = if ($null -ne $_.metrics.elapsed_ms) { [double]$_.metrics.elapsed_ms } else { 0 }
            created_at = [string]$_.created_at
        }
    }
)

$HealthStatus = "unknown"
$ModelCount = 0
if ($LatestHealth.Count -gt 0) {
    $HealthStatus = [string]$LatestHealth[0].status
    $ModelCount = @($LatestHealth[0].models).Count
}

$Snapshot = [ordered]@{
    phase = "Self-Hosted AI Office"
    generated_at = (Get-Date).ToString("o")
    status = if ($HealthStatus -eq "healthy") { "operational" } else { "attention" }
    runtime = [ordered]@{
        provider = "ollama"
        endpoint = "http://127.0.0.1:11434"
        health = $HealthStatus
        available_models = $ModelCount
    }
    metrics = [ordered]@{
        providers = [int]$Index.provider_count
        connected_providers = [int]$Index.connected_provider_count
        models = [int]$Index.model_count
        ready_models = [int]$Index.ready_model_count
        routing_rules = [int]$Index.routing_rule_count
        hardware_profiles = [int]$Index.hardware_profile_count
        inference_results = @($Inference).Count
    }
    hardware = if ($LatestHardware.Count -gt 0) {
        [ordered]@{
            hostname = [string]$LatestHardware[0].hostname
            memory_gb = [double]$LatestHardware[0].memory.total_gb
            gpu = @($LatestHardware[0].gpu)
        }
    } else {
        [ordered]@{ hostname=""; memory_gb=0; gpu=@() }
    }
    recent_inference = $RecentInference
}

$Output = "E:\AI\AI-Office\dashboard\public\data\self-hosting.json"
Write-AIOfficeSelfHostingJson -Value $Snapshot -Path $Output

Write-Host "Self-Hosting dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
