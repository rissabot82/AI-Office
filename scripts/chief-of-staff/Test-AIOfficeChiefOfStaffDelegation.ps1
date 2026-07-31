param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.4 Part C Delegation and Dispatch..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\chief-of-staff\delegation-policy.json",
    ".\config\chief-of-staff\delegation-schema.json",
    ".\config\chief-of-staff\work-package-schema.json",
    ".\workspace\templates\chief-of-staff-delegation-template.json",
    ".\workspace\templates\chief-of-staff-work-package-template.json"
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
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffDelegation.Common.ps1",
    ".\scripts\chief-of-staff\Route-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffWorkPackage.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffDelegation.ps1",
    ".\scripts\chief-of-staff\Send-AIOfficeChiefOfStaffDelegation.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1",
    ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1",
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffDelegation.ps1"
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
$DelegationId = ""
$WorkPackageId = ""
$MessageId = ""

try {
    $Plan = & ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1" `
        -Title "Create Facebook campaign for Elite Auto Sales" `
        -Objective "Create and prepare a dealership Facebook campaign." `
        -SuccessCriteriaJson '["Campaign plan created","Creative assigned","Execution prepared"]' `
        -Priority "high" `
        -RiskLevel "low" `
        -ApprovalStatus "not_required"

    $PlanId = [string]$Plan.plan_id

    $Route = & ".\scripts\chief-of-staff\Route-AIOfficeChiefOfStaffPlan.ps1" `
        -PlanId $PlanId

    if ([string]$Route.department -ne "marketing") {
        throw "Expected marketing route, received $($Route.department)."
    }

    Write-Host "[ROUTE OK   ] $($Route.department)" `
        -ForegroundColor Green
}
catch {
    Write-Host "[ROUTE ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Routing failed: " + $_.Exception.Message)
}

try {
    $Dispatch = & `
        ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1" `
        -PlanId $PlanId

    $DelegationId = [string]$Dispatch.delegation.delegation_id
    $WorkPackageId = [string]$Dispatch.work_package.work_package_id
    $MessageId = [string]$Dispatch.message.message_id

    if ([string]::IsNullOrWhiteSpace($DelegationId) -or
        [string]::IsNullOrWhiteSpace($WorkPackageId) -or
        [string]::IsNullOrWhiteSpace($MessageId)) {
        throw "Dispatch did not produce expected IDs."
    }

    Write-Host (
        "[DISPATCH OK] " +
        $DelegationId +
        " | " +
        $MessageId
    ) -ForegroundColor Green
}
catch {
    Write-Host "[DISPATCH ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Dispatch failed: " + $_.Exception.Message)
}

try {
    $Delegations = @(
        & ".\scripts\chief-of-staff\Show-AIOfficeChiefOfStaffDelegations.ps1"
    )

    if ($Delegations.Count -lt 1) {
        throw "Delegation monitor returned no records."
    }

    Write-Host (
        "[MONITOR OK ] " +
        $Delegations.Count.ToString() +
        " delegation(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[MONITOR ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Monitoring failed: " + $_.Exception.Message)
}

foreach ($Path in @(
    ".\workspace\chief-of-staff\plans\$PlanId.json",
    ".\workspace\chief-of-staff\delegations\$DelegationId.json",
    ".\workspace\chief-of-staff\work-packages\$WorkPackageId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\chief-of-staff\routing" `
    -Filter "RTE-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Route = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Route.plan_id -eq $PlanId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

if ($MessageId) {
    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Path = ".\workspace\messages\$Queue\$MessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Delegation and Dispatch error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.4 Part C Delegation and Dispatch checks passed." `
    -ForegroundColor Green
