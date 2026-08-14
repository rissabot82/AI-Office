param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part B Local Model Inventory and Benchmark Harness..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\intelligence\benchmark-runtime-policy.json",
    ".\config\intelligence\model-benchmark-result-schema.json",
    ".\workspace\templates\intelligence-benchmark-result-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        $Errors.Add("Invalid JSON: $File")
        Write-Host "[JSON ERR] $File" -ForegroundColor Red
    }
}

$Scripts = @(
    ".\scripts\intelligence\New-AIOfficeIntelligenceId.ps1",
    ".\scripts\intelligence\Get-AIOfficeModelInventory.ps1",
    ".\scripts\intelligence\Invoke-AIOfficeModelBenchmarkCase.ps1",
    ".\scripts\intelligence\Invoke-AIOfficeModelBenchmark.ps1",
    ".\scripts\intelligence\Get-AIOfficeBenchmarkStatus.ps1",
    ".\scripts\intelligence\Test-AIOfficeBenchmarkHarness.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
        Write-Host "[SCRIPT ERR] $Script" -ForegroundColor Red
    }
}

try {
    $Inventory = & ".\scripts\intelligence\Get-AIOfficeModelInventory.ps1" -Persist

    if ([int]$Inventory.model_count -lt 1) {
        throw "No installed models were found."
    }

    Write-Host "[INVENTORY OK] $($Inventory.model_count) model(s)" -ForegroundColor Green

    foreach ($Model in @($Inventory.models)) {
        Write-Host ("  - " + [string]$Model.model) -ForegroundColor DarkGray
    }
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[INVENTORY ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Smoke = & ".\scripts\intelligence\Invoke-AIOfficeModelBenchmark.ps1" `
        -SmokeTest `
        -Persist

    if ([int]$Smoke.result_count -lt 1) {
        throw "Smoke benchmark produced no results."
    }

    if ([int]$Smoke.failed_count -gt 0) {
        throw "One or more models failed the smoke benchmark."
    }

    Write-Host "[SMOKE BENCHMARK OK] $($Smoke.completed_count)/$($Smoke.result_count) completed" -ForegroundColor Green

    foreach ($Result in @($Smoke.results)) {
        Write-Host (
            "  - " + [string]$Result.model +
            " | " + [string]$Result.elapsed_ms + " ms" +
            " | " + [string]$Result.response
        ) -ForegroundColor DarkGray
    }
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[BENCHMARK ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Status = & ".\scripts\intelligence\Get-AIOfficeBenchmarkStatus.ps1"

    if ([int]$Status.benchmark_runs -lt 1) {
        throw "Benchmark run persistence was not verified."
    }

    Write-Host "[PERSISTENCE OK] Runs=$($Status.benchmark_runs) | Results=$($Status.benchmark_results)" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[PERSISTENCE ERR] $($_.Exception.Message)" -ForegroundColor Red
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }

    Write-Host ""
    throw "$($Errors.Count) Local Model Inventory and Benchmark Harness error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part B Local Model Inventory and Benchmark Harness checks passed." -ForegroundColor Green
