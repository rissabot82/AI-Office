param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part I External Intelligence Provider Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($Json in @(
    ".\config\intelligence\external-provider-policy.json",
    ".\config\intelligence\external-provider-schema.json",
    ".\workspace\templates\external-provider-template.json"
)) {
    try {
        Get-Content $Json -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $Json" -ForegroundColor Green
    }
    catch {
        $Errors.Add("Invalid JSON: $Json")
    }
}

foreach ($Script in @(
    ".\scripts\intelligence\Get-AIOfficeExternalProviderStatus.ps1",
    ".\scripts\intelligence\Show-AIOfficeExternalProviderStatus.ps1",
    ".\scripts\intelligence\Resolve-AIOfficeExternalProvider.ps1",
    ".\scripts\intelligence\Test-AIOfficeExternalProviderArchitecture.ps1"
)) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Policy = Get-Content ".\config\intelligence\external-provider-policy.json" -Raw | ConvertFrom-Json

    if ([bool]$Policy.enabled) {
        throw "External provider execution must remain disabled in Part I."
    }

    if ([bool]$Policy.automatic_paid_inference) {
        throw "Automatic paid inference must remain disabled in Part I."
    }

    if ([double]$Policy.guardrails.daily_budget_usd -ne 0) {
        throw "Part I daily budget must default to zero."
    }

    if ([double]$Policy.guardrails.monthly_budget_usd -ne 0) {
        throw "Part I monthly budget must default to zero."
    }

    Write-Host "[COST SAFETY OK] External execution disabled; budgets default to $0." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $RawPolicy = Get-Content ".\config\intelligence\external-provider-policy.json" -Raw

    if ($RawPolicy -match 'sk-[A-Za-z0-9_-]{10,}') {
        throw "Potential API credential found in repository policy."
    }

    Write-Host "[SECRET SAFETY OK] No API secret values stored in provider policy." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Local = & ".\scripts\intelligence\Resolve-AIOfficeExternalProvider.ps1" -RequiresEscalation $false
    if ([string]$Local.route -ne "local" -or -not [bool]$Local.executable) {
        throw "Non-escalated request did not remain local."
    }

    $Escalated = & ".\scripts\intelligence\Resolve-AIOfficeExternalProvider.ps1" -RequiresEscalation $true
    if ([string]$Escalated.route -ne "external_advisory" -or [bool]$Escalated.executable) {
        throw "Escalated request should be advisory-only before activation."
    }

    Write-Host "[ROUTER OK] Local requests stay local; escalation remains advisory." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    if (-not $Runtime.Contains("Invoke-AIOfficeQualityControlledInference.ps1")) {
        throw "Part G live quality-controlled inference is missing."
    }

    if (-not $Runtime.Contains("Invoke-AIOfficeOptimizedInference.ps1")) {
        throw "v2.4 fallback is missing."
    }

    Write-Host "[PRODUCTION SAFETY OK] Live conversational runtime remains unchanged." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) External Intelligence Provider Architecture error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part I External Intelligence Provider Architecture checks passed." -ForegroundColor Green
