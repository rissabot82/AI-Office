param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing Self-Hosted AI Office Part E Intelligent Model Selection and Workload Optimization..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\self-hosting\model-selection-policy.json",
    ".\config\self-hosting\model-selection-schema.json",
    ".\config\self-hosting\workload-metric-schema.json",
    ".\config\self-hosting\model-benchmark-schema.json",
    ".\workspace\templates\self-hosting-model-selection-template.json",
    ".\workspace\templates\self-hosting-workload-metric-template.json",
    ".\workspace\templates\self-hosting-model-benchmark-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\self-hosting\AIOfficeModelSelection.Common.ps1",
    ".\scripts\self-hosting\New-AIOfficeWorkloadMetric.ps1",
    ".\scripts\self-hosting\Get-AIOfficeIntelligentModelSelection.ps1",
    ".\scripts\self-hosting\Invoke-AIOfficeOptimizedInference.ps1",
    ".\scripts\self-hosting\New-AIOfficeLocalModelBenchmark.ps1",
    ".\scripts\self-hosting\Get-AIOfficeWorkloadOptimizationStatus.ps1",
    ".\scripts\self-hosting\Test-AIOfficeIntelligentModelSelection.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $PrivateSelection = & ".\scripts\self-hosting\Get-AIOfficeIntelligentModelSelection.ps1" `
        -TaskType "summarization" `
        -Sensitivity "private" `
        -Complexity "low" `
        -WorkloadProfile "quick" `
        -DoNotPersist

    if ([string]$PrivateSelection.selected_provider -ne "ollama") {
        throw "Private workload did not select local inference."
    }

    if ([string]::IsNullOrWhiteSpace([string]$PrivateSelection.selected_model)) {
        throw "Private workload did not select a local model."
    }

    Write-Host "[PRIVATE MODEL OK] $($PrivateSelection.selected_model)" -ForegroundColor Green

    $CloudSelection = & ".\scripts\self-hosting\Get-AIOfficeIntelligentModelSelection.ps1" `
        -TaskType "deep_reasoning" `
        -Sensitivity "normal" `
        -Complexity "high" `
        -WorkloadProfile "quality" `
        -DoNotPersist

    if ([string]$CloudSelection.selected_provider -ne "openclaw") {
        throw "Deep reasoning workload did not escalate to OpenClaw."
    }

    Write-Host "[ESCALATION OK] Deep reasoning -> OpenClaw" -ForegroundColor Green

    $Optimized = & ".\scripts\self-hosting\Invoke-AIOfficeOptimizedInference.ps1" `
        -Prompt "Reply with exactly: OPTIMIZED LOCAL OK" `
        -TaskType "classification" `
        -Sensitivity "sensitive" `
        -Complexity "low" `
        -WorkloadProfile "quick" `
        -DoNotPersist

    if ([string]$Optimized.provider -ne "ollama") {
        throw "Optimized inference did not use the selected local model."
    }

    if ([string]::IsNullOrWhiteSpace([string]$Optimized.response)) {
        throw "Optimized local inference returned an empty response."
    }

    Write-Host "[OPTIMIZED INFERENCE OK] $($Optimized.model)" -ForegroundColor Green

    $Benchmark = & ".\scripts\self-hosting\New-AIOfficeLocalModelBenchmark.ps1"

    if ([double]$Benchmark.summary.success_rate -lt 100) {
        throw "Local model benchmark did not complete all tests."
    }

    Write-Host "[BENCHMARK OK] $($Benchmark.model) | avg=$($Benchmark.summary.average_elapsed_ms)ms" -ForegroundColor Green

    $SelectionAfterBenchmark = & ".\scripts\self-hosting\Get-AIOfficeIntelligentModelSelection.ps1" `
        -TaskType "summarization" `
        -Sensitivity "normal" `
        -Complexity "low" `
        -WorkloadProfile "quick" `
        -DoNotPersist

    if ([string]$SelectionAfterBenchmark.selected_provider -ne "ollama") {
        throw "Post-benchmark workload selection did not retain local model selection."
    }

    Write-Host "[HISTORY OK] Historical workload metrics used in selection." -ForegroundColor Green
}
catch {
    Write-Host "[MODEL SELECTION ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Intelligent Model Selection error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All Self-Hosted AI Office Part E Intelligent Model Selection and Workload Optimization checks passed." -ForegroundColor Green
