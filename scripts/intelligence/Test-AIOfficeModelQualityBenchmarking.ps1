param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part C Model Quality Benchmarking..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($File in @(
    ".\config\intelligence\quality-scoring-policy.json",
    ".\config\intelligence\quality-evaluation-schema.json",
    ".\workspace\templates\intelligence-quality-evaluation-template.json"
)) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\intelligence\Test-AIOfficeBenchmarkRequirement.ps1",
    ".\scripts\intelligence\Measure-AIOfficeBenchmarkQuality.ps1",
    ".\scripts\intelligence\Invoke-AIOfficeIntelligenceQualityBenchmark.ps1",
    ".\scripts\intelligence\Show-AIOfficeIntelligenceQualityReport.ps1",
    ".\scripts\intelligence\Test-AIOfficeModelQualityBenchmarking.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Run = & ".\scripts\intelligence\Invoke-AIOfficeIntelligenceQualityBenchmark.ps1" -Persist

    $ExpectedResults = [int]$Run.benchmark_result_count
    $CompletedResults = [int]$Run.benchmark_completed_count
    $FailedResults = [int]$Run.benchmark_failed_count

    if ($ExpectedResults -lt 1) {
        throw "Quality benchmark produced no benchmark results."
    }

    $Coverage = [double]$CompletedResults / [double]$ExpectedResults

    if ($Coverage -lt 0.80) {
        throw ("Quality benchmark coverage is too low: {0:P1}" -f $Coverage)
    }

    if (@($Run.rankings).Count -lt 1) {
        throw "Quality rankings were not generated."
    }

    foreach ($ModelResult in @($Run.rankings)) {
        $ModelCoverage = if ([int]$ModelResult.total_cases -gt 0) {
            [double]$ModelResult.total_cases / 8.0
        }
        else {
            0.0
        }

        if ($ModelCoverage -lt 0.75) {
            throw (
                "Model benchmark coverage is too low for " +
                [string]$ModelResult.model +
                ": " +
                ("{0:P1}" -f $ModelCoverage)
            )
        }
    }

    if ($FailedResults -gt 0) {
        Write-Host (
            "[BENCHMARK WARN] " +
            $FailedResults +
            " model/case execution(s) failed; completed coverage=" +
            ("{0:P1}" -f $Coverage)
        ) -ForegroundColor Yellow
    }

    Write-Host (
        "[QUALITY RUN OK] " +
        $Run.evaluation_count +
        " evaluations | coverage=" +
        ("{0:P1}" -f $Coverage)
    ) -ForegroundColor Green

    & ".\scripts\intelligence\Show-AIOfficeIntelligenceQualityReport.ps1" -QualityRun $Run

    $Top = @($Run.rankings)[0]

    if ([string]::IsNullOrWhiteSpace([string]$Top.model)) {
        throw "Top-ranked model is missing."
    }

    Write-Host ("[RANKING OK] Top model: " + [string]$Top.model + " | score=" + [string]$Top.average_score) -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[QUALITY ERR] $($_.Exception.Message)" -ForegroundColor Red
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) Model Quality Benchmarking error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part C Model Quality Benchmarking checks passed." -ForegroundColor Green

