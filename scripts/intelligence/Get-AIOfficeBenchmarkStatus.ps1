param()

$ErrorActionPreference = "Stop"

$BenchmarkDirectory = "E:\AI\AI-Office\workspace\intelligence\benchmarks"
$RunDirectory = "E:\AI\AI-Office\workspace\intelligence\benchmark-runs"
$InventoryDirectory = "E:\AI\AI-Office\workspace\intelligence\inventories"

$Benchmarks = @(
    Get-ChildItem -LiteralPath $BenchmarkDirectory -Filter "INTBENCH-*.json" -File -ErrorAction SilentlyContinue
)

$Runs = @(
    Get-ChildItem -LiteralPath $RunDirectory -Filter "INTRUN-*.json" -File -ErrorAction SilentlyContinue
)

$Inventories = @(
    Get-ChildItem -LiteralPath $InventoryDirectory -Filter "INTINV-*.json" -File -ErrorAction SilentlyContinue
)

return [pscustomobject]@{
    benchmark_results = $Benchmarks.Count
    benchmark_runs = $Runs.Count
    inventories = $Inventories.Count
    latest_run = if ($Runs.Count -gt 0) { ($Runs | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name } else { "" }
    checked_at = (Get-Date).ToString("o")
}
