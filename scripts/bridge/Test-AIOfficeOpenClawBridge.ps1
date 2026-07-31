param(
    [switch]$AuthenticatedConnectionTest,
    [switch]$LiveExecutionTest
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.3 OpenClaw Bridge..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-BridgeTest {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Path
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

Invoke-BridgeTest `
    -Name "Part A Bridge Architecture" `
    -Path ".\scripts\bridge\Test-AIOfficeBridgeArchitecture.ps1"

Invoke-BridgeTest `
    -Name "Part B Live Execution Engine" `
    -Path ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1"

Invoke-BridgeTest `
    -Name "Part C Result Processing" `
    -Path ".\scripts\bridge\Test-AIOfficeResultProcessing.ps1"

try {
    $Arguments = @{}

    if ($AuthenticatedConnectionTest) {
        $Arguments.AuthenticatedConnectionTest = $true
    }

    if ($LiveExecutionTest) {
        $Arguments.LiveExecutionTest = $true
    }

    $Certification = & `
        ".\scripts\bridge\Certify-AIOfficeOpenClawBridge.ps1" `
        @Arguments

    if ($null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0) {
        throw "OpenClaw Bridge certification failed."
    }

    Write-Host (
        "[PASS] Bridge certification: " +
        [string]$Certification.certification_id +
        " | mode=" +
        [string]$Certification.mode
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Bridge certification" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Bridge certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " OpenClaw Bridge error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.3 OpenClaw Bridge checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.1.3 OpenClaw Bridge is operational." `
    -ForegroundColor Cyan
