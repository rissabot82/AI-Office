param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part H Quality Escalation Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    $Policy = Get-Content ".\config\intelligence\quality-escalation-policy.json" -Raw | ConvertFrom-Json
    Write-Host "[VALID JSON] .\config\intelligence\quality-escalation-policy.json" -ForegroundColor Green

    if ([bool]$Policy.automatic_external_escalation_enabled) {
        throw "Part H must not silently enable external/cloud execution."
    }

    Write-Host "[SAFETY OK] External escalation is advisory only." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

foreach ($Script in @(
    ".\scripts\intelligence\Resolve-AIOfficeQualityEscalation.ps1",
    ".\scripts\intelligence\Show-AIOfficeQualityEscalation.ps1",
    ".\scripts\intelligence\Test-AIOfficeQualityEscalation.ps1"
)) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    } else {
        $Errors.Add("Missing script: $Script")
    }
}

$Cases = @(
    [pscustomobject]@{
        name="strong_reasoning"
        content="Explain why doubling both sides of a ratio leaves the ratio unchanged."
        family="reasoning"
        model="deepseek-r1:1.5b"
        score=0.9908
        complexity="medium"
        expected=$false
    },
    [pscustomobject]@{
        name="weak_coding"
        content="Debug this production PowerShell architecture and provide a robust fix."
        family="coding"
        model="qwen2.5-coder:3b"
        score=0.6000
        complexity="high"
        expected=$true
    },
    [pscustomobject]@{
        name="high_quality_creative"
        content="Create a polished advertising campaign concept for a dealership."
        family="creative"
        model="qwen2.5-coder:3b"
        score=1.0000
        complexity="high"
        expected=$true
    }
)

foreach ($Case in $Cases) {
    try {
        $Result = & ".\scripts\intelligence\Resolve-AIOfficeQualityEscalation.ps1" `
            -Content $Case.content `
            -TaskFamily $Case.family `
            -SelectedModel $Case.model `
            -ModelScore $Case.score `
            -Complexity $Case.complexity

        if ([bool]$Result.requires_escalation -ne [bool]$Case.expected) {
            throw "$($Case.name): expected escalation=$($Case.expected), got $($Result.requires_escalation)."
        }

        Write-Host "[ESCALATION OK] $($Case.name) -> $($Result.requires_escalation)" -ForegroundColor Green
    }
    catch {
        $Errors.Add($_.Exception.Message)
        Write-Host "[ESCALATION ERR] $($_.Exception.Message)" -ForegroundColor Red
    }
}

try {
    $LiveRuntime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    if (-not $LiveRuntime.Contains("Invoke-AIOfficeQualityControlledInference.ps1")) {
        throw "Part G live quality control is no longer present."
    }

    if (-not $LiveRuntime.Contains("Invoke-AIOfficeOptimizedInference.ps1")) {
        throw "v2.4 fallback is no longer present."
    }

    Write-Host "[PRODUCTION SAFETY OK] Part H did not replace the working live inference path." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }
    throw "$($Errors.Count) Quality Escalation Architecture error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part H Quality Escalation Architecture checks passed." -ForegroundColor Green
