param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing Self-Hosted AI Office Part F Local Model Fleet and Specialized Models..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\self-hosting\model-fleet-policy.json",
    ".\config\self-hosting\model-fleet-schema.json",
    ".\workspace\templates\self-hosting-model-fleet-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\self-hosting\Get-AIOfficeModelFleetPolicy.ps1",
    ".\scripts\self-hosting\Install-AIOfficeFleetModel.ps1",
    ".\scripts\self-hosting\Sync-AIOfficeSpecializedModelProfiles.ps1",
    ".\scripts\self-hosting\New-AIOfficeModelFleetSnapshot.ps1",
    ".\scripts\self-hosting\Initialize-AIOfficeLocalModelFleet.ps1",
    ".\scripts\self-hosting\Test-AIOfficeLocalModelFleet.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Fleet = & ".\scripts\self-hosting\New-AIOfficeModelFleetSnapshot.ps1"

    if ([string]$Fleet.status -ne "ready") {
        throw "Required model fleet is not ready."
    }

    $General = @(
        $Fleet.models |
        Where-Object { [string]$_.role -eq "general" }
    )

    $Code = @(
        $Fleet.models |
        Where-Object { [string]$_.role -eq "code" }
    )

    if ($General.Count -ne 1 -or -not [bool]$General[0].installed) {
        throw "General model is not installed."
    }

    if ($Code.Count -ne 1 -or -not [bool]$Code[0].installed) {
        throw "Code model is not installed."
    }

    Write-Host "[GENERAL MODEL OK] $($General[0].configured_model)" -ForegroundColor Green
    Write-Host "[CODE MODEL OK] $($Code[0].configured_model)" -ForegroundColor Green

    $GeneralRun = & ".\scripts\self-hosting\Invoke-AIOfficeLocalInference.ps1" `
        -Prompt "Reply with exactly: GENERAL MODEL OK" `
        -Model ([string]$General[0].configured_model) `
        -DoNotPersist

    if ([string]::IsNullOrWhiteSpace([string]$GeneralRun.response)) {
        throw "General model returned an empty response."
    }

    Write-Host "[GENERAL INFERENCE OK]" -ForegroundColor Green

    $CodeRun = & ".\scripts\self-hosting\Invoke-AIOfficeLocalInference.ps1" `
        -Prompt "Return only this PowerShell expression: 2+2" `
        -Model ([string]$Code[0].configured_model) `
        -DoNotPersist

    if ([string]::IsNullOrWhiteSpace([string]$CodeRun.response)) {
        throw "Code model returned an empty response."
    }

    Write-Host "[CODE INFERENCE OK]" -ForegroundColor Green

    $Profiles = & ".\scripts\self-hosting\Sync-AIOfficeSpecializedModelProfiles.ps1"

    if (@($Profiles).Count -lt 2) {
        throw "Specialized model profile synchronization returned fewer than two models."
    }

    Write-Host "[PROFILE SYNC OK] $(@($Profiles).Count) model profile(s)." -ForegroundColor Green
}
catch {
    Write-Host "[MODEL FLEET ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Local Model Fleet error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All Self-Hosted AI Office Part F Local Model Fleet and Specialized Models checks passed." -ForegroundColor Green
