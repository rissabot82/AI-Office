param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing Self-Hosted AI Office Part D Model Routing and Hybrid Execution..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\self-hosting\hybrid-routing-policy.json",
    ".\config\self-hosting\routing-decision-schema.json",
    ".\config\self-hosting\hybrid-execution-result-schema.json",
    ".\workspace\templates\self-hosting-routing-decision-template.json",
    ".\workspace\templates\self-hosting-hybrid-execution-result-template.json"
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
    ".\scripts\self-hosting\AIOfficeHybridRouting.Common.ps1",
    ".\scripts\self-hosting\Get-AIOfficeModelRoutingDecision.ps1",
    ".\scripts\self-hosting\Invoke-AIOfficeHybridInference.ps1",
    ".\scripts\self-hosting\Get-AIOfficeHybridRoutingStatus.ps1",
    ".\scripts\self-hosting\Test-AIOfficeHybridRouting.ps1"
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
    $PrivateDecision = & ".\scripts\self-hosting\Get-AIOfficeModelRoutingDecision.ps1" `
        -TaskType "private_context" `
        -Sensitivity "private" `
        -Complexity "low" `
        -DoNotPersist

    if ([string]$PrivateDecision.selected_provider -ne "ollama") {
        throw "Private routing did not select Ollama."
    }

    Write-Host "[PRIVATE ROUTE OK] provider=ollama" -ForegroundColor Green

    $ComplexDecision = & ".\scripts\self-hosting\Get-AIOfficeModelRoutingDecision.ps1" `
        -TaskType "deep_reasoning" `
        -Sensitivity "normal" `
        -Complexity "high" `
        -DoNotPersist

    if ([string]$ComplexDecision.selected_provider -ne "openclaw") {
        throw "High-complexity routing did not select OpenClaw."
    }

    Write-Host "[CLOUD ROUTE OK] provider=openclaw" -ForegroundColor Green

    $LocalResult = & ".\scripts\self-hosting\Invoke-AIOfficeHybridInference.ps1" `
        -Prompt "Reply with exactly: HYBRID LOCAL OK" `
        -TaskType "classification" `
        -Sensitivity "sensitive" `
        -Complexity "low" `
        -ExplicitMode "local_only" `
        -DoNotPersist

    if ([string]$LocalResult.provider -ne "ollama") {
        throw "Hybrid local execution did not use Ollama."
    }

    if ([string]::IsNullOrWhiteSpace([string]$LocalResult.response)) {
        throw "Hybrid local execution returned an empty response."
    }

    Write-Host "[LOCAL EXECUTION OK] Ollama generated a response." -ForegroundColor Green

    $CloudResult = & ".\scripts\self-hosting\Invoke-AIOfficeHybridInference.ps1" `
        -Prompt "Certification cloud route." `
        -TaskType "deep_reasoning" `
        -Sensitivity "normal" `
        -Complexity "high" `
        -DoNotPersist

    if ([string]$CloudResult.provider -ne "openclaw") {
        throw "Hybrid cloud execution did not route to OpenClaw."
    }

    Write-Host "[HYBRID ROUTE OK] OpenClaw route available." -ForegroundColor Green
}
catch {
    Write-Host "[HYBRID ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Model Routing and Hybrid Execution error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All Self-Hosted AI Office Part D Model Routing and Hybrid Execution checks passed." -ForegroundColor Green
