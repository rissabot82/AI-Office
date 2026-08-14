param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part K End-to-End Intelligence Certification..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($Json in @(
    ".\config\intelligence\end-to-end-certification-policy.json",
    ".\workspace\templates\intelligence-certification-template.json"
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
    ".\scripts\intelligence\Certify-AIOfficeIntelligenceUpgrade.ps1",
    ".\scripts\intelligence\Test-AIOfficeEndToEndIntelligenceCertification.ps1"
)) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

$RequiredTests = @(
    "Test-AIOfficeIntelligenceArchitecture.ps1",
    "Test-AIOfficeBenchmarkHarness.ps1",
    "Test-AIOfficeModelQualityBenchmarking.ps1",
    "Test-AIOfficeIntelligentModelSelection.ps1",
    "Test-AIOfficeLiveIntelligenceIntegration.ps1",
    "Test-AIOfficeIntelligenceOperations.ps1",
    "Test-AIOfficeResponseQualityControl.ps1",
    "Test-AIOfficeQualityEscalation.ps1",
    "Test-AIOfficeExternalProviderArchitecture.ps1",
    "Test-AIOfficeLiveEscalationCostGuardrails.ps1"
)

foreach ($Name in $RequiredTests) {
    $Path = Join-Path ".\scripts\intelligence" $Name
    if (Test-Path -LiteralPath $Path) {
        Write-Host "[PART PRESENT] $Name" -ForegroundColor Green
    }
    else {
        $Errors.Add("Required v2.5 certification test is missing: $Name")
    }
}

try {
    $Policy = Get-Content ".\config\intelligence\end-to-end-certification-policy.json" -Raw | ConvertFrom-Json
    if ([bool]$Policy.live_external_call_required) {
        throw "Part K must not require a paid external call for structural certification."
    }
    Write-Host "[COST SAFETY OK] Certification does not require paid external inference." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) { Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red }
    throw "$($Errors.Count) End-to-End Intelligence Certification architecture error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part K End-to-End Intelligence Certification checks passed." -ForegroundColor Green
