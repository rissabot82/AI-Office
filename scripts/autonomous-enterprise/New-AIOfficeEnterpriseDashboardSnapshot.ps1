param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

$IndexPath = "E:\AI\AI-Office\workspace\autonomous-enterprise\indexes\enterprise-index.json"

& "E:\AI\AI-Office\scripts\autonomous-enterprise\Update-AIOfficeEnterpriseIndex.ps1" | Out-Null
$Index = Read-AIOfficeEnterpriseJson -Path $IndexPath

if ($null -eq $Index) {
    throw "Enterprise index unavailable."
}

$Runs = Get-AIOfficeEnterpriseCollection `
    -Directory "E:\AI\AI-Office\workspace\autonomous-enterprise\runs" `
    -Filter "ENTRUN-*.json"

$RecentRuns = @(
    $Runs |
    Sort-Object { [string]$_.updated_at } -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        [ordered]@{
            enterprise_run_id = [string]$_.enterprise_run_id
            work_title = [string]$_.work_title
            status = [string]$_.status
            completed_steps = @($_.completed_steps).Count
            failed_steps = @($_.failed_steps).Count
            updated_at = [string]$_.updated_at
        }
    }
)

$Snapshot = [ordered]@{
    version = "2.0.0"
    release_name = "Autonomous AI Enterprise"
    generated_at = (Get-Date).ToString("o")
    status = [string]$Index.status
    metrics = [ordered]@{
        work_items = [int]$Index.work_item_count
        active_work_items = [int]$Index.active_work_item_count
        plans = [int]$Index.plan_count
        active_plans = [int]$Index.active_plan_count
        departments = [int]$Index.department_count
        capabilities = [int]$Index.capability_count
        runs = @($Runs).Count
        completed_runs = @($Runs | Where-Object { [string]$_.status -eq "completed" }).Count
        failed_runs = @($Runs | Where-Object { [string]$_.status -eq "failed" }).Count
    }
    domain_counts = $Index.domain_counts
    status_counts = $Index.status_counts
    recent_runs = $RecentRuns
}

$Output = "E:\AI\AI-Office\dashboard\public\data\autonomous-enterprise.json"
Write-AIOfficeEnterpriseJson -Value $Snapshot -Path $Output

Write-Host "Autonomous AI Enterprise dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
