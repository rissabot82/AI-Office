param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Index = Get-Content `
    -LiteralPath "E:\AI\AI-Office\workspace\self-hosting\indexes\self-hosting-index.json" `
    -Raw |
    ConvertFrom-Json

$ServiceHealth = & "E:\AI\AI-Office\scripts\self-hosting\Test-AIOfficeSelfHostingServiceHealth.ps1"
$Resources = & "E:\AI\AI-Office\scripts\self-hosting\Get-AIOfficeResourceSnapshot.ps1"

$FleetFiles = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\fleets" `
    -Filter "SHFLEET-*.json"

$Benchmarks = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\benchmarks" `
    -Filter "SHBENCH-*.json"

$RoutingDecisions = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\routing-decisions" `
    -Filter "SHDEC-*.json"

$ModelSelections = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\model-selections" `
    -Filter "SHSEL-*.json"

$Failovers = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\failover-events" `
    -Filter "SHFAIL-*.json"

$Recoveries = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\recovery" `
    -Filter "SHREC-*.json"

$LatestFleet = @(
    $FleetFiles |
    Sort-Object { [string]$_.updated_at } -Descending |
    Select-Object -First 1
)

$LatestBenchmark = @(
    $Benchmarks |
    Sort-Object { [string]$_.created_at } -Descending |
    Select-Object -First 1
)

$FleetModels = if ($LatestFleet.Count -gt 0) { @($LatestFleet[0].models) } else { @() }
$ReadyFleetModels = @($FleetModels | Where-Object { [bool]$_.installed -and [string]$_.status -eq "ready" })

$Snapshot = [ordered]@{
    version = "2.2.0"
    release_name = "Self-Hosted AI Office"
    generated_at = (Get-Date).ToString("o")
    overall_status = if (
        [string]$ServiceHealth.status -eq "healthy" -and
        [int]$Index.ready_model_count -ge 1
    ) { "operational" } else { "attention" }

    services = [ordered]@{
        ollama = [bool]$ServiceHealth.ollama
        openclaw_gateway = [bool]$ServiceHealth.openclaw_gateway
        dashboard = [bool]$ServiceHealth.dashboard
    }

    resources = [ordered]@{
        cpu_percent = [double]$Resources.cpu_percent
        memory_percent = [double]$Resources.memory_percent
        system_drive_free_gb = [double]$Resources.system_drive_free_gb
        ai_drive_free_gb = [double]$Resources.ai_drive_free_gb
        gpu = $Resources.gpu
        warnings = @($Resources.warnings)
    }

    local_inference = [ordered]@{
        providers = [int]$Index.provider_count
        connected_providers = [int]$Index.connected_provider_count
        registered_models = [int]$Index.model_count
        ready_models = [int]$Index.ready_model_count
        routing_rules = [int]$Index.routing_rule_count
        fleet_models = @($FleetModels).Count
        ready_fleet_models = @($ReadyFleetModels).Count
    }

    optimization = [ordered]@{
        routing_decisions = @($RoutingDecisions).Count
        model_selections = @($ModelSelections).Count
        benchmarks = @($Benchmarks).Count
        latest_benchmark_success_rate = if ($LatestBenchmark.Count -gt 0) {
            [double]$LatestBenchmark[0].summary.success_rate
        } else { 0 }
    }

    resilience = [ordered]@{
        failover_events = @($Failovers).Count
        recovery_records = @($Recoveries).Count
        failed_recoveries = @($Recoveries | Where-Object { [string]$_.status -eq "failed" }).Count
    }
}

$Output = "E:\AI\AI-Office\dashboard\public\data\self-hosting-final.json"
Write-AIOfficeSelfHostingJson -Value $Snapshot -Path $Output

Write-Host "Self-Hosted AI Office final dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
