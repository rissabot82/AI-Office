param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.4 Part A Chief of Staff Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\chief-of-staff\chief-of-staff-identity.json",
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\config\chief-of-staff\plan-schema.json",
    ".\config\chief-of-staff\decision-schema.json",
    ".\workspace\chief-of-staff\chief-of-staff-index.json",
    ".\workspace\templates\chief-of-staff-plan-template.json",
    ".\workspace\templates\chief-of-staff-decision-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDecision.ps1",
    ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1",
    ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffStatus.ps1",
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffArchitecture.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

$PlanId = ""
$DecisionId = ""

try {
    $Plan = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1" `
        -Title "Chief of Staff architecture validation" `
        -Objective "Confirm planning, approval, and decision records work." `
        -SuccessCriteriaJson '["Plan created","Approval policy evaluated","Decision recorded"]' `
        -Priority "high" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required"

    $PlanId = [string]$Plan.plan_id

    if ([string]::IsNullOrWhiteSpace($PlanId)) {
        throw "Plan ID was not created."
    }

    Write-Host "[PLAN OK    ] $PlanId" -ForegroundColor Green
}
catch {
    Write-Host "[PLAN ERR   ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Plan creation failed: " + $_.Exception.Message)
}

try {
    $Decision = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDecision.ps1" `
        -PlanId $PlanId `
        -Decision "Proceed with Chief of Staff integration." `
        -Reason "Architecture validation passed." `
        -RiskLevel "low"

    $DecisionId = [string]$Decision.decision_id

    if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        throw "Decision ID was not created."
    }

    Write-Host "[DECISION OK] $DecisionId" -ForegroundColor Green
}
catch {
    Write-Host "[DECISION ER] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Decision creation failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1"

    if ($null -eq $Index -or [int]$Index.open_plan_count -lt 1) {
        throw "Chief of Staff index did not contain the test plan."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.open_plan_count +
        " open plan(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Index validation failed: " + $_.Exception.Message)
}

if ($PlanId) {
    $Path = ".\workspace\chief-of-staff\plans\$PlanId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if ($DecisionId) {
    $Path = ".\workspace\chief-of-staff\decisions\$DecisionId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Chief of Staff architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.4 Part A Chief of Staff Architecture checks passed." `
    -ForegroundColor Green
