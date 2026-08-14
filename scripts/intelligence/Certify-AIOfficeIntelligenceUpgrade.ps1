param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$CertificationId = "CERT-INTELLIGENCE-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$Checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name,[bool]$Passed,[string]$Details)
    $Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

function Invoke-CertificationScript {
    param([string]$Name,[string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Check -Name $Name -Passed $false -Details ("Missing: " + $Path)
        return
    }

    try {
        $Output = & powershell -ExecutionPolicy Bypass -File $Path 2>&1 | Out-String
        Add-Check -Name $Name -Passed $true -Details $Output.Trim()
    }
    catch {
        Add-Check -Name $Name -Passed $false -Details $_.Exception.Message
    }
}

$Tests = @(
    @("Part A Intelligence Architecture","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeIntelligenceArchitecture.ps1"),
    @("Part B Benchmark Harness","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeBenchmarkHarness.ps1"),
    @("Part C Model Quality Benchmarking","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeModelQualityBenchmarking.ps1"),
    @("Part D Intelligent Model Selection","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeIntelligentModelSelection.ps1"),
    @("Part E Live Intelligence Integration","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeLiveIntelligenceIntegration.ps1"),
    @("Part F Intelligence Operations","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeIntelligenceOperations.ps1"),
    @("Part G Response Quality Control","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeResponseQualityControl.ps1"),
    @("Part H Quality Escalation","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeQualityEscalation.ps1"),
    @("Part I External Provider Architecture","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeExternalProviderArchitecture.ps1"),
    @("Part J Cost Guardrails","E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeLiveEscalationCostGuardrails.ps1")
)

foreach ($Test in $Tests) {
    Invoke-CertificationScript -Name $Test[0] -Path $Test[1]
}

try {
    $Models = @(& "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeInstalledModels.ps1")
    if ($Models.Count -lt 1) { throw "No local Ollama models discovered." }
    Add-Check -Name "Local Model Availability" -Passed $true -Details ("Installed local models: " + $Models.Count)
}
catch {
    Add-Check -Name "Local Model Availability" -Passed $false -Details $_.Exception.Message
}

try {
    $Runtime = Get-Content "E:\AI\AI-Office\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    if (-not $Runtime.Contains("Invoke-AIOfficeQualityControlledInference.ps1")) {
        throw "Quality-controlled inference is not wired into the conversation runtime."
    }

    if (-not $Runtime.Contains("Invoke-AIOfficeOptimizedInference.ps1")) {
        throw "v2.4 optimized local fallback is missing."
    }

    Add-Check -Name "Runtime Wiring and Fallback" -Passed $true -Details "Quality-controlled intelligence and v2.4 fallback are both present."
}
catch {
    Add-Check -Name "Runtime Wiring and Fallback" -Passed $false -Details $_.Exception.Message
}

try {
    $Policy = Get-Content "E:\AI\AI-Office\config\intelligence\live-escalation-policy.json" -Raw | ConvertFrom-Json

    if ([double]$Policy.cost_guardrails.daily_budget_usd -le 0) { throw "Daily cost guardrail is invalid." }
    if ([double]$Policy.cost_guardrails.monthly_budget_usd -le 0) { throw "Monthly cost guardrail is invalid." }
    if ([double]$Policy.cost_guardrails.max_estimated_request_cost_usd -le 0) { throw "Per-request cost guardrail is invalid." }

    Add-Check -Name "External Cost Safety" -Passed $true -Details (
        "Daily=$" + $Policy.cost_guardrails.daily_budget_usd +
        "; Monthly=$" + $Policy.cost_guardrails.monthly_budget_usd +
        "; PerRequest=$" + $Policy.cost_guardrails.max_estimated_request_cost_usd +
        "; Enabled=" + $Policy.enabled
    )
}
catch {
    Add-Check -Name "External Cost Safety" -Passed $false -Details $_.Exception.Message
}

try {
    $DiscordOps = "E:\AI\AI-Office\scripts\discord-office\Show-AIOfficeDiscordOperations.ps1"
    if (-not (Test-Path -LiteralPath $DiscordOps -PathType Leaf)) {
        throw "Discord operations script is missing."
    }

    $Output = & powershell -ExecutionPolicy Bypass -File $DiscordOps 2>&1 | Out-String
    Add-Check -Name "Discord Operations Availability" -Passed $true -Details $Output.Trim()
}
catch {
    Add-Check -Name "Discord Operations Availability" -Passed $false -Details $_.Exception.Message
}

$Passed = @($Checks | Where-Object { $_.passed }).Count
$Failed = @($Checks | Where-Object { -not $_.passed }).Count
$Status = if ($Failed -eq 0) { "passed" } else { "failed" }

$Result = [ordered]@{
    certification_id = $CertificationId
    version = "2.5.0"
    release_name = "Intelligence Upgrade"
    status = $Status
    passed_checks = $Passed
    failed_checks = $Failed
    checks = $Checks.ToArray()
    certified_at = (Get-Date).ToString("o")
}

$Directory = "E:\AI\AI-Office\workspace\intelligence\certifications"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null
$Path = Join-Path $Directory ($CertificationId + ".json")
$Result | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding UTF8

Write-Host ""
Write-Host "AI OFFICE v2.5 END-TO-END INTELLIGENCE CERTIFICATION" -ForegroundColor Cyan
Write-Host "==================================================="
Write-Host ("Status: " + $Status + " | Passed=" + $Passed + " | Failed=" + $Failed) -ForegroundColor $(if ($Failed -eq 0) {"Green"} else {"Red"})
Write-Host ""

foreach ($Check in $Checks) {
    $Prefix = if ($Check.passed) { "[PASS]" } else { "[FAIL]" }
    $Color = if ($Check.passed) { "Green" } else { "Red" }
    Write-Host ($Prefix + " " + $Check.name) -ForegroundColor $Color
}

Write-Host ""
Write-Host ("Certification: " + $Path) -ForegroundColor Cyan

return [pscustomobject]$Result
