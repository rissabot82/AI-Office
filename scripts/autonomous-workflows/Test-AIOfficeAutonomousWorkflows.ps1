param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.4 Autonomous Workflows..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

function Invoke-AutonomousTest {
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

Invoke-AutonomousTest `
    -Name "Part A Autonomous Workflow Architecture" `
    -Path ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousWorkflowArchitecture.ps1"

Invoke-AutonomousTest `
    -Name "Part B Autonomous Execution and Recovery" `
    -Path ".\scripts\autonomous-workflows\Test-AIOfficeAutonomousExecution.ps1"

try {
    $Certification = & `
        ".\scripts\autonomous-workflows\Certify-AIOfficeAutonomousWorkflows.ps1"

    if (
        $null -eq $Certification -or
        [string]$Certification.status -ne "certified" -or
        [int]$Certification.failed_checks -ne 0
    ) {
        throw "Autonomous Workflows certification failed."
    }

    Write-Host (
        "[PASS] Autonomous Workflows certification: " +
        [string]$Certification.certification_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Autonomous Workflows certification" `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Autonomous Workflows certification: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Autonomous Workflows error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.4 Autonomous Workflows checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.4 Autonomous Workflows is operational." `
    -ForegroundColor Cyan
