param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Selections = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\model-selections" `
    -Filter "SHSEL-*.json"

$Metrics = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\workload-metrics" `
    -Filter "SHMET-*.json"

$Benchmarks = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\benchmarks" `
    -Filter "SHBENCH-*.json"

$AverageElapsed = ($Metrics | Measure-Object -Property elapsed_ms -Average).Average

$Status = [ordered]@{
    selections = @($Selections).Count
    local_selections = @($Selections | Where-Object { [string]$_.selected_provider -eq "ollama" }).Count
    cloud_selections = @($Selections | Where-Object { [string]$_.selected_provider -eq "openclaw" }).Count
    workload_metrics = @($Metrics).Count
    benchmarks = @($Benchmarks).Count
    average_elapsed_ms = if ($null -ne $AverageElapsed) { [math]::Round([double]$AverageElapsed,2) } else { 0 }
    generated_at = (Get-Date).ToString("o")
}

Write-Host ""
Write-Host "AI OFFICE WORKLOAD OPTIMIZATION" -ForegroundColor Cyan
Write-Host ("=" * 64)
Write-Host ("Model Selections   : " + $Status.selections)
Write-Host ("Local Selections   : " + $Status.local_selections)
Write-Host ("Cloud Selections   : " + $Status.cloud_selections)
Write-Host ("Workload Metrics   : " + $Status.workload_metrics)
Write-Host ("Benchmarks         : " + $Status.benchmarks)
Write-Host ("Average Runtime ms : " + $Status.average_elapsed_ms)
Write-Host ""

return [pscustomobject]$Status
