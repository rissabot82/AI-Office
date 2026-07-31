param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.3 Long-Term Memory..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-MemoryTest {
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

Invoke-MemoryTest `
    -Name "Part A Memory Architecture" `
    -Path ".\scripts\memory\Test-AIOfficeMemoryArchitecture.ps1"

Invoke-MemoryTest `
    -Name "Part B Capture, Search, and Recall" `
    -Path ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1"

try {
    $Certification = & `
        ".\scripts\memory\Certify-AIOfficeLongTermMemory.ps1"

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "Long-Term Memory certification failed."
    }

    Write-Host (
        "[PASS] Long-Term Memory certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Long-Term Memory certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Long-Term Memory certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Long-Term Memory error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.3 Long-Term Memory checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.3 Long-Term Memory is operational." `
    -ForegroundColor Cyan
