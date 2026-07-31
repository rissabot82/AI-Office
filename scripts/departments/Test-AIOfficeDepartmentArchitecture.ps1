param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Part A Department Intelligence Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$RequiredJson = @(
    ".\config\departments\department-intelligence-policy.json",
    ".\config\departments\department-profile-schema.json",
    ".\config\departments\department-capability-schema.json",
    ".\workspace\departments\index\department-intelligence-index.json",
    ".\workspace\templates\department-profile-template.json"
)

foreach ($Department in @(
    "marketing",
    "creative",
    "website",
    "analytics",
    "finance",
    "business",
    "side-hustles",
    "youtube",
    "personal-assistant"
)) {
    $RequiredJson += ".\config\departments\$Department\department-profile.json"
    $RequiredJson += ".\config\departments\$Department\capabilities.json"
    $RequiredJson += ".\workspace\departments\$Department\department-index.json"
}

foreach ($File in $RequiredJson) {
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
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1",
    ".\scripts\departments\Show-AIOfficeDepartmentStatus.ps1",
    ".\scripts\departments\Get-AIOfficeDepartment.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1"
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

try {
    . ".\scripts\departments\AIOfficeDepartments.Common.ps1"

    $Marketing = & ".\scripts\departments\Get-AIOfficeDepartment.ps1" `
        -Department "marketing"

    if ($null -eq $Marketing -or
        [string]$Marketing.profile.slug -ne "marketing" -or
        -not (
            Test-AIOfficeDepartmentCapability `
                -Department "marketing" `
                -Capability "google_ads"
        )) {
        throw "Marketing department profile validation failed."
    }

    Write-Host "[PROFILE OK ] Marketing Department" `
        -ForegroundColor Green
}
catch {
    Write-Host "[PROFILE ERR] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Department profile test failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1"

    if ($null -eq $Index -or
        [int]$Index.department_count -ne 9 -or
        [int]$Index.active_department_count -ne 9) {
        throw "Department index did not contain nine active departments."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.department_count +
        " departments"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Department index failed: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Intelligence architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Part A Department Intelligence Architecture checks passed." `
    -ForegroundColor Green
