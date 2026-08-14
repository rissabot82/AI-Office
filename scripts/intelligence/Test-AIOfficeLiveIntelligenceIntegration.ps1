param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part E Live Intelligence Integration..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    Get-Content ".\config\intelligence\live-integration-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\intelligence\live-integration-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid live integration policy JSON.")
}

foreach ($Script in @(
    ".\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1",
    ".\scripts\intelligence\Test-AIOfficeLiveIntelligenceIntegration.ps1",
    ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1"
)) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Selection = & ".\scripts\intelligence\Select-AIOfficeIntelligentModel.ps1" `
        -Content "Write a short silly poem about a cat driving a Kia."

    if ([string]$Selection.task_family -ne "creative") {
        throw "Expected creative task family."
    }

    Write-Host "[SELECTOR OK] creative -> $($Selection.selected_model)" -ForegroundColor Green

    $Inference = & ".\scripts\intelligence\Invoke-AIOfficeSelectedLocalInference.ps1" `
        -Model ([string]$Selection.selected_model) `
        -Prompt "Reply with exactly: LIVE INTELLIGENCE OK"

    if ([string]$Inference.response -notmatch "LIVE INTELLIGENCE OK") {
        throw "Selected local inference did not return the expected smoke response."
    }

    Write-Host "[SELECTED INFERENCE OK] $($Inference.model) | $($Inference.elapsed_ms) ms" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[LIVE INTELLIGENCE ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    foreach ($Required in @(
        "Select-AIOfficeIntelligentModel.ps1",
        "Invoke-AIOfficeQualityControlledInference.ps1",
        "Invoke-AIOfficeOptimizedInference.ps1",
        "intelligence_fallback_used"
    )) {
        if (-not $Runtime.Contains($Required)) {
            throw "Conversational runtime is missing integration marker: $Required"
        }
    }

    Write-Host "[RUNTIME WIRING OK] Intelligent selector + v2.4 fallback are both present." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[RUNTIME WIRING ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Policy = Get-Content ".\config\intelligence\live-integration-policy.json" -Raw | ConvertFrom-Json

    if (-not [bool]$Policy.live_integration.preserve_v24_fallback) {
        throw "v2.4 fallback protection is disabled."
    }

    Write-Host "[ROLLBACK SAFETY OK] v2.4 inference fallback preserved." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) Live Intelligence Integration error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part E Live Intelligence Integration checks passed." -ForegroundColor Green



