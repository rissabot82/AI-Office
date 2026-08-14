param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part A Intelligence Upgrade Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\intelligence\intelligence-policy.json",
    ".\config\intelligence\benchmark-suite.json",
    ".\config\intelligence\model-capability-schema.json",
    ".\workspace\templates\intelligence-model-capability-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        $Errors.Add("$File is invalid JSON: $($_.Exception.Message)")
        Write-Host "[JSON ERR] $File" -ForegroundColor Red
    }
}

$Scripts = @(
    ".\scripts\intelligence\Get-AIOfficeIntelligenceArchitecture.ps1",
    ".\scripts\intelligence\Get-AIOfficeInstalledModels.ps1",
    ".\scripts\intelligence\Test-AIOfficeIntelligenceArchitecture.ps1"
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
    $Architecture = & ".\scripts\intelligence\Get-AIOfficeIntelligenceArchitecture.ps1"

    if ([string]$Architecture.version -ne "2.5.0") {
        throw "Unexpected intelligence architecture version."
    }

    if ([int]$Architecture.benchmark_cases -lt 8) {
        throw "Benchmark suite does not contain the expected baseline cases."
    }

    Write-Host "[ARCHITECTURE OK] $($Architecture.task_families.Count) task families | $($Architecture.benchmark_cases) benchmark cases" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[ARCHITECTURE ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Models = @(& ".\scripts\intelligence\Get-AIOfficeInstalledModels.ps1")

    if ($Models.Count -eq 0) {
        Write-Host "[MODEL INVENTORY WARN] No Ollama models discovered from this shell." -ForegroundColor Yellow
    }
    else {
        Write-Host "[MODEL INVENTORY OK] $($Models.Count) installed Ollama model(s) discovered." -ForegroundColor Green
        foreach ($Model in $Models) {
            Write-Host ("  - " + $Model.model) -ForegroundColor DarkGray
        }
    }
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[MODEL INVENTORY ERR] $($_.Exception.Message)" -ForegroundColor Red
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($ErrorItem in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $ErrorItem" -ForegroundColor Red
    }

    Write-Host ""
    throw "$($Errors.Count) Intelligence Upgrade Architecture error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part A Intelligence Upgrade Architecture checks passed." -ForegroundColor Green
