param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Department Intelligence..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-DepartmentTest {
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

Invoke-DepartmentTest `
    -Name "Part A Department Architecture" `
    -Path ".\scripts\departments\Test-AIOfficeDepartmentArchitecture.ps1"

Invoke-DepartmentTest `
    -Name "Part B Department Inbox" `
    -Path ".\scripts\departments\Test-AIOfficeDepartmentInbox.ps1"

Invoke-DepartmentTest `
    -Name "Part C Department Execution" `
    -Path ".\scripts\departments\Test-AIOfficeDepartmentExecution.ps1"

try {
    $Certification = & `
        ".\scripts\departments\Certify-AIOfficeDepartmentIntelligence.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Department Intelligence certification failed."
    }

    Write-Host (
        "[PASS] Department Intelligence certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Department Intelligence certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Department Intelligence certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Intelligence error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Department Intelligence checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.2 Department Intelligence is operational." `
    -ForegroundColor Cyan
