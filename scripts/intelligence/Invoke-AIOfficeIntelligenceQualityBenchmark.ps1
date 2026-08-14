param(
    [string[]]$Models = @(),
    [switch]$Persist
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Suite = Get-Content `
    -LiteralPath ".\config\intelligence\benchmark-suite.json" `
    -Raw |
    ConvertFrom-Json

if ($Models.Count -eq 0) {
    $Inventory = & ".\scripts\intelligence\Get-AIOfficeModelInventory.ps1"
    $Models = @($Inventory.models | ForEach-Object { [string]$_.model })
}

if ($Models.Count -eq 0) {
    throw "No installed models found."
}

$BenchmarkRun = & ".\scripts\intelligence\Invoke-AIOfficeModelBenchmark.ps1" `
    -Models $Models `
    -Persist:$Persist

# Individual model/case failures are benchmark evidence, not automatically
# a failure of the benchmark subsystem. Completed results continue to quality
# evaluation; certification later verifies sufficient benchmark coverage.

$Evaluations = New-Object System.Collections.Generic.List[object]

foreach ($Result in @($BenchmarkRun.results)) {

    if ([string]$Result.status -ne "completed") {
        continue
    }

    $Case = @($Suite.cases | Where-Object { [string]$_.id -eq [string]$Result.case_id })[0]

    if ($null -eq $Case) {
        continue
    }

    $Evaluation = & ".\scripts\intelligence\Measure-AIOfficeBenchmarkQuality.ps1" `
        -BenchmarkResult $Result `
        -BenchmarkCase $Case `
        -Persist:$Persist

    $Evaluations.Add($Evaluation)
}

$ModelSummaries = New-Object System.Collections.Generic.List[object]

foreach ($Model in $Models) {
    $ModelEvals = @($Evaluations | Where-Object { [string]$_.model -eq [string]$Model })

    $OverallAverage = ($ModelEvals | Measure-Object -Property overall_score -Average).Average
    $PassCount = @($ModelEvals | Where-Object { [bool]$_.passed }).Count

    $ByFamily = [ordered]@{}

    foreach ($Family in @($Suite.cases.family | Select-Object -Unique)) {
        $FamilyEvals = @($ModelEvals | Where-Object { [string]$_.family -eq [string]$Family })

        if ($FamilyEvals.Count -gt 0) {
            $ByFamily[$Family] = [math]::Round(
                [double](($FamilyEvals | Measure-Object -Property overall_score -Average).Average),
                4
            )
        }
    }

    $ModelSummaries.Add([pscustomobject]@{
        model = $Model
        average_score = if ($null -eq $OverallAverage) { 0 } else { [math]::Round([double]$OverallAverage,4) }
        passed_cases = $PassCount
        total_cases = $ModelEvals.Count
        family_scores = [pscustomobject]$ByFamily
    })
}

$Ranked = @($ModelSummaries | Sort-Object average_score -Descending)

$Summary = [ordered]@{
    quality_run_id = "INTQUALITY-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    models = @($Models)
    benchmark_run_id = [string]$BenchmarkRun.run_id
    benchmark_result_count = [int]$BenchmarkRun.result_count
    benchmark_completed_count = [int]$BenchmarkRun.completed_count
    benchmark_failed_count = [int]$BenchmarkRun.failed_count
    evaluation_count = $Evaluations.Count
    rankings = $Ranked
    evaluations = $Evaluations.ToArray()
    created_at = (Get-Date).ToString("o")
}

if ($Persist) {
    $Directory = "E:\AI\AI-Office\workspace\intelligence\quality-runs"
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null

    $Summary |
        ConvertTo-Json -Depth 100 |
        Set-Content `
            -LiteralPath (Join-Path $Directory ($Summary.quality_run_id + ".json")) `
            -Encoding UTF8
}

return [pscustomobject]$Summary

