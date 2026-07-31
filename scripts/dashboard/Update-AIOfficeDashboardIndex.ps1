param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

$snapshotFolder = ".\workspace\dashboard\snapshots"
$indexPath = ".\workspace\dashboard\dashboard-index.json"

$snapshots = @(
    Get-ChildItem `
        -LiteralPath $snapshotFolder `
        -Filter "DSH-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object {
        $snapshot = Read-AIOfficeJsonFile -Path $_.FullName

        if ($null -ne $snapshot) {
            [ordered]@{
                snapshot_id = [string]$snapshot.snapshot_id
                generated_at = [string]$snapshot.generated_at
                health_score = [int]$snapshot.overall_health.score
                health_status = [string]$snapshot.overall_health.status
                risk_count = [int]$snapshot.overall_health.risk_count
                file = $_.Name
            }
        }
    }
)

$latestSnapshot = ""

if ($snapshots.Count -gt 0) {
    $latestSnapshot = [string]$snapshots[0].file
}

$index = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    latest_snapshot = $latestSnapshot
    snapshot_count = [int]$snapshots.Count
    snapshots = @($snapshots)
}

$index |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $indexPath -Encoding UTF8

Write-Host (
    "Dashboard index updated: " +
    $snapshots.Count.ToString() +
    " snapshot(s)."
) -ForegroundColor Green

return [pscustomobject]$index
