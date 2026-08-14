param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part J Live Escalation and Cost Guardrails..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    $Policy = Get-Content ".\config\intelligence\live-escalation-policy.json" -Raw | ConvertFrom-Json
    Write-Host "[VALID JSON] .\config\intelligence\live-escalation-policy.json" -ForegroundColor Green

    if ([string]$Policy.provider -ne "openai") { throw "Expected provider=openai." }
    if ([string]$Policy.model -ne "gpt-5.6-luna") { throw "Expected model=gpt-5.6-luna." }
    if ([double]$Policy.cost_guardrails.daily_budget_usd -le 0) { throw "Daily budget must be positive." }
    if ([double]$Policy.cost_guardrails.monthly_budget_usd -le 0) { throw "Monthly budget must be positive." }

    Write-Host "[POLICY OK] OpenAI GPT-5.6 Luna | local-first | guarded." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

foreach ($Script in @(
    ".\scripts\intelligence\Get-AIOfficeExternalUsage.ps1",
    ".\scripts\intelligence\Test-AIOfficeExternalCostGuardrail.ps1",
    ".\scripts\intelligence\Enable-AIOfficeLiveEscalation.ps1",
    ".\scripts\intelligence\Disable-AIOfficeLiveEscalation.ps1",
    ".\scripts\intelligence\Test-AIOfficeLiveEscalationCostGuardrails.ps1"
)) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    } else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Cheap = & ".\scripts\intelligence\Test-AIOfficeExternalCostGuardrail.ps1" -EstimatedRequestCostUsd 0.01
    if (-not [bool]$Cheap.allowed) {
        throw "A $0.01 test request should fit fresh default guardrails."
    }

    $Expensive = & ".\scripts\intelligence\Test-AIOfficeExternalCostGuardrail.ps1" -EstimatedRequestCostUsd 1.00
    if ([bool]$Expensive.allowed) {
        throw "A $1.00 request should be blocked by the per-request guardrail."
    }

    Write-Host "[COST GUARDRAIL OK] Small request allowed; oversized request blocked." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Policy = Get-Content ".\config\intelligence\live-escalation-policy.json" -Raw | ConvertFrom-Json

    if ([bool]$Policy.enabled) {
        Write-Host "[ACTIVATION STATE] Live escalation is ENABLED." -ForegroundColor Yellow
    } else {
        Write-Host "[ACTIVATION SAFETY OK] Live escalation remains OFF until explicitly enabled." -ForegroundColor Green
    }
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    if (-not $Runtime.Contains("Invoke-AIOfficeQualityControlledInference.ps1")) {
        throw "Part G quality-controlled inference is missing."
    }
    if (-not $Runtime.Contains("Invoke-AIOfficeOptimizedInference.ps1")) {
        throw "v2.4 local fallback is missing."
    }

    Write-Host "[PRODUCTION SAFETY OK] Existing local runtime remains intact." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) { Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red }
    throw "$($Errors.Count) Live Escalation and Cost Guardrails error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part J Live Escalation and Cost Guardrails checks passed." -ForegroundColor Green
