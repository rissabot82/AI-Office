param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part D Intelligent Model Selection..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($File in @(
    ".\config\intelligence\model-selection-policy.json",
    ".\config\intelligence\model-benchmark-baseline.json",
    ".\config\intelligence\model-selection-result-schema.json",
    ".\workspace\templates\intelligence-model-selection-template.json"
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
    ".\scripts\intelligence\Get-AIOfficeModelSelectionPolicy.ps1",
    ".\scripts\intelligence\Get-AIOfficeModelBenchmarkBaseline.ps1",
    ".\scripts\intelligence\Resolve-AIOfficeTaskFamily.ps1",
    ".\scripts\intelligence\Resolve-AIOfficeQualityTier.ps1",
    ".\scripts\intelligence\Select-AIOfficeIntelligentModel.ps1",
    ".\scripts\intelligence\Show-AIOfficeIntelligentModelSelection.ps1",
    ".\scripts\intelligence\Test-AIOfficeIntelligentModelSelection.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

$Cases = @(
    [pscustomobject]@{
        name = "conversation"
        prompt = "Hello! How are you today?"
        expected_family = "conversation"
        expected_model = "qwen2.5-coder:3b"
        expected_escalation = $false
    },
    [pscustomobject]@{
        name = "reasoning"
        prompt = "Reason through why doubling both numbers in a ratio leaves the ratio unchanged."
        expected_family = "reasoning"
        expected_model = "deepseek-r1:1.5b"
        expected_escalation = $false
    },
    [pscustomobject]@{
        name = "creative"
        prompt = "Write a silly poem about a cat driving a Kia."
        expected_family = "creative"
        expected_model = "qwen2.5-coder:3b"
        expected_escalation = $false
    },
    [pscustomobject]@{
        name = "drafting"
        prompt = "Draft a concise follow-up email to a vendor."
        expected_family = "drafting"
        expected_model = "qwen2.5:3b"
        expected_escalation = $false
    },
    [pscustomobject]@{
        name = "analysis"
        prompt = "Analyze and compare campaign performance by cost per lead."
        expected_family = "analysis"
        expected_model = "qwen2.5:3b"
        expected_escalation = $false
    },
    [pscustomobject]@{
        name = "classification"
        prompt = "Classify this request into the correct department."
        expected_family = "classification"
        expected_model = "qwen2.5:3b"
        expected_escalation = $false
    },
    [pscustomobject]@{
        name = "coding"
        prompt = "Debug this PowerShell script and explain the parser error."
        expected_family = "coding"
        expected_model = "qwen2.5-coder:3b"
        expected_escalation = $true
    }
)

foreach ($Case in $Cases) {
    try {
        $Selection = & ".\scripts\intelligence\Select-AIOfficeIntelligentModel.ps1" `
            -Content ([string]$Case.prompt) `
            -Persist

        if ([string]$Selection.task_family -ne [string]$Case.expected_family) {
            throw "Expected family $($Case.expected_family), got $($Selection.task_family)."
        }

        if ([string]$Selection.selected_model -ne [string]$Case.expected_model) {
            throw "Expected model $($Case.expected_model), got $($Selection.selected_model)."
        }

        if ([bool]$Selection.requires_escalation -ne [bool]$Case.expected_escalation) {
            throw "Unexpected escalation state for $($Case.name)."
        }

        Write-Host (
            "[SELECTION OK] " +
            $Case.name +
            " -> " +
            [string]$Selection.selected_model +
            " | tier=" +
            [string]$Selection.quality_tier +
            " | score=" +
            [string]$Selection.selected_family_score +
            " | escalation=" +
            [string]$Selection.requires_escalation
        ) -ForegroundColor Green
    }
    catch {
        $Errors.Add("$($Case.name): $($_.Exception.Message)")
        Write-Host "[SELECTION ERR] $($Case.name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

try {
    $Policy = & ".\scripts\intelligence\Get-AIOfficeModelSelectionPolicy.ps1"

    if ([bool]$Policy.selection.production_integration_enabled) {
        throw "Part D must not enable production routing."
    }

    Write-Host "[PRODUCTION SAFETY OK] Live routing remains unchanged." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) Intelligent Model Selection error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part D Intelligent Model Selection checks passed." -ForegroundColor Green

