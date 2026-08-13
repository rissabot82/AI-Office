param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Resources = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\resource-snapshots" `
    -Filter "SHRES-*.json"

$Failovers = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\failover-events" `
    -Filter "SHFAIL-*.json"

$Recovery = Get-AIOfficeSelfHostingCollection `
    -Directory "E:\AI\AI-Office\workspace\self-hosting\recovery" `
    -Filter "SHREC-*.json"

$Status = [ordered]@{
    resource_snapshots = @($Resources).Count
    failover_events = @($Failovers).Count
    recovery_records = @($Recovery).Count
    successful_recoveries = @($Recovery | Where-Object { [string]$_.status -eq "completed" }).Count
    failed_recoveries = @($Recovery | Where-Object { [string]$_.status -eq "failed" }).Count
    generated_at = (Get-Date).ToString("o")
}

Write-Host ""
Write-Host "AI OFFICE RESILIENCE STATUS" -ForegroundColor Cyan
Write-Host ("=" * 64)
Write-Host ("Resource Snapshots : " + $Status.resource_snapshots)
Write-Host ("Failover Events     : " + $Status.failover_events)
Write-Host ("Recovery Records    : " + $Status.recovery_records)
Write-Host ("Successful Recovery : " + $Status.successful_recoveries)
Write-Host ("Failed Recovery     : " + $Status.failed_recoveries)
Write-Host ""

return [pscustomobject]$Status
