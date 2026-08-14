param(
    [string[]]$Models = @(),
    [string[]]$CaseIds = @(),
    [switch]$SmokeTest,
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

$Suite = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\benchmark-suite.json" `
    -Raw |
    ConvertFrom-Json

if ($Models.Count -eq 0) {
    $Inventory = & "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeModelInventory.ps1"
    $Models = @($Inventory.models | ForEach-Object { [string]$_.model })
}

if ($Models.Count -eq 0) {
    throw "No installed Ollama models were found."
}

if ($SmokeTest) {
    $Cases = @(
        [pscustomobject]@{
            id = "INT-SMOKE-001"
            family = "conversation"
            quality_tier = "fast"
            prompt = "Reply with exactly: BENCHMARK OK"
        }
    )
}
elseif ($CaseIds.Count -gt 0) {
    $Cases = @(
        $Suite.cases |
        Where-Object { $CaseIds -contains [string]$_.id }
    )

    if ($Cases.Count -eq 0) {
        throw "No benchmark cases matched the supplied CaseIds."
    }
}
else {
    $Cases = @($Suite.cases)
}

$RunId = "INTRUN-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
$StartedAt = Get-Date
$Results = New-Object System.Collections.Generic.List[object]

foreach ($Model in $Models) {
    foreach ($Case in $Cases) {
        Write-Host ("Benchmarking " + $Model + " | " + $Case.id + "...") -ForegroundColor Cyan

        $Result = & "E:\AI\AI-Office\scripts\intelligence\Invoke-AIOfficeModelBenchmarkCase.ps1" `
            -Model $Model `
            -CaseId ([string]$Case.id) `
            -Family ([string]$Case.family) `
            -QualityTier ([string]$Case.quality_tier) `
            -Prompt ([string]$Case.prompt) `
            -Persist:$Persist

        $Results.Add($Result)

        $Color = if ([string]$Result.status -eq "completed") { "Green" } else { "Red" }
        Write-Host (
            "  " + [string]$Result.status +
            " | " + [string]$Result.elapsed_ms + " ms"
        ) -ForegroundColor $Color
    }
}

$Completed = @($Results | Where-Object { [string]$_.status -eq "completed" }).Count
$Failed = @($Results | Where-Object { [string]$_.status -eq "failed" }).Count
$Average = ($Results | Where-Object { [string]$_.status -eq "completed" } | Measure-Object -Property elapsed_ms -Average).Average

$Summary = [ordered]@{
    run_id = $RunId
    mode = if ($SmokeTest) { "smoke" } else { "suite" }
    models = @($Models)
    case_count = $Cases.Count
    result_count = $Results.Count
    completed_count = $Completed
    failed_count = $Failed
    average_elapsed_ms = if ($null -eq $Average) { 0 } else { [math]::Round([double]$Average,2) }
    started_at = $StartedAt.ToString("o")
    completed_at = (Get-Date).ToString("o")
    results = $Results.ToArray()
}

if ($Persist) {
    $Directory = "E:\AI\AI-Office\workspace\intelligence\benchmark-runs"
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null

    $Summary |
        ConvertTo-Json -Depth 100 |
        Set-Content `
            -LiteralPath (Join-Path $Directory ($RunId + ".json")) `
            -Encoding UTF8
}

return [pscustomobject]$Summary
