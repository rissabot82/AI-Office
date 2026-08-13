param(
    [string]$Model = ""
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing Self-Hosted AI Office Part B Local Inference Runtime..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\self-hosting\runtime-policy.json",
    ".\config\self-hosting\runtime-health-schema.json",
    ".\config\self-hosting\inference-result-schema.json",
    ".\workspace\templates\self-hosting-runtime-health-template.json",
    ".\workspace\templates\self-hosting-inference-result-template.json"
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
    ".\scripts\self-hosting\AIOfficeLocalInference.Common.ps1",
    ".\scripts\self-hosting\Install-AIOfficeOllamaRuntime.ps1",
    ".\scripts\self-hosting\Sync-AIOfficeOllamaModels.ps1",
    ".\scripts\self-hosting\Install-AIOfficeDefaultLocalModel.ps1",
    ".\scripts\self-hosting\Test-AIOfficeLocalInferenceHealth.ps1",
    ".\scripts\self-hosting\Invoke-AIOfficeLocalInference.ps1",
    ".\scripts\self-hosting\Initialize-AIOfficeLocalInferenceRuntime.ps1",
    ".\scripts\self-hosting\Test-AIOfficeLocalInferenceRuntime.ps1"
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
    . ".\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

    $Policy = Get-AIOfficeLocalInferencePolicy

    if ([string]::IsNullOrWhiteSpace($Model)) {
        $Model = [string]$Policy.default_model
    }

    $Executable = Get-AIOfficeOllamaExecutable

    if ($null -eq $Executable) {
        throw "Ollama executable was not found."
    }

    Write-Host "[OLLAMA OK] $Executable" -ForegroundColor Green

    $Health = & ".\scripts\self-hosting\Test-AIOfficeLocalInferenceHealth.ps1"

    if ([string]$Health.status -ne "healthy") {
        throw "Ollama API is not healthy."
    }

    Write-Host "[HEALTH OK] $($Health.endpoint)" -ForegroundColor Green

    $ModelAvailable = $false
    foreach ($InstalledModel in @($Health.models)) {
        if (
            [string]$InstalledModel -eq $Model -or
            [string]$InstalledModel -eq ($Model + ":latest")
        ) {
            $ModelAvailable = $true
            break
        }
    }

    if (-not $ModelAvailable) {
        throw "Default model is not installed: $Model"
    }

    Write-Host "[MODEL OK] $Model" -ForegroundColor Green

    $Result = & ".\scripts\self-hosting\Invoke-AIOfficeLocalInference.ps1" `
        -Prompt ([string]$Policy.validation.test_prompt) `
        -Model $Model `
        -DoNotPersist

    if ([string]$Result.status -ne "completed") {
        throw "Local inference generation did not complete."
    }

    if ([string]::IsNullOrWhiteSpace([string]$Result.response)) {
        throw "Local inference returned an empty response."
    }

    Write-Host "[INFERENCE OK] $($Result.model)" -ForegroundColor Green
    Write-Host "[LOCAL RESPONSE] $([string]$Result.response)" -ForegroundColor DarkCyan

    $Index = & ".\scripts\self-hosting\Update-AIOfficeSelfHostingIndex.ps1"

    if ([int]$Index.connected_provider_count -lt 1) {
        throw "No connected self-hosted provider is registered."
    }

    if ([int]$Index.ready_model_count -lt 1) {
        throw "No ready local models are registered."
    }

    Write-Host "[INDEX OK] Provider and local model registered." -ForegroundColor Green
}
catch {
    Write-Host "[RUNTIME ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Local Inference Runtime error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All Self-Hosted AI Office Part B Local Inference Runtime checks passed." -ForegroundColor Green
