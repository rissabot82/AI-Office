param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.4 Chief of Staff Integration..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-COSTest {
    param(
        [string]$Name,
        [string]$Path
    )

    try {
        & $Path

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "$Name returned exit code $LASTEXITCODE."
        }

        Write-Host ("[PASS] " + $Name) -ForegroundColor Green
    }
    catch {
        Write-Host ("[FAIL] " + $Name) -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $Errors.Add($Name + ": " + $_.Exception.Message)
    }
}

Invoke-COSTest `
    -Name "Part A Chief of Staff Architecture" `
    -Path ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffArchitecture.ps1"

Invoke-COSTest `
    -Name "Part B Executive Inbox and Planning" `
    -Path ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffInbox.ps1"

Invoke-COSTest `
    -Name "Part C Delegation and Dispatch" `
    -Path ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaffDelegation.ps1"

try {
    $Certification = & `
        ".\scripts\chief-of-staff\Certify-AIOfficeChiefOfStaff.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Chief of Staff certification failed."
    }

    Write-Host (
        "[PASS] Chief of Staff certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Chief of Staff certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Chief of Staff certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Chief of Staff Integration error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.4 Chief of Staff Integration checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.1.4 Chief of Staff Integration is operational." `
    -ForegroundColor Cyan
