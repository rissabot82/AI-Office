param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.1 Identity System..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\identity\office.json",
    ".\config\identity\capabilities.json",
    ".\config\identity\version.json",
    ".\config\identity\api-schema.json",
    ".\workspace\identity\identity-index.json"
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
    ".\scripts\identity\AIOfficeIdentity.Common.ps1",
    ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1",
    ".\scripts\identity\Show-AIOfficeIdentity.ps1",
    ".\scripts\identity\Export-AIOfficeIdentity.ps1",
    ".\scripts\identity\Test-AIOfficeIdentity.ps1"
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
    $Index = & ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1"

    if ($null -eq $Index -or
        [string]$Index.office_version -ne "1.1.1" -or
        -not [bool]$Index.identity_valid) {
        throw "Identity index did not contain expected values."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$Index.office_id +
        " v" +
        [string]$Index.office_version
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] Identity indexing failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Identity indexing failed: " + $_.Exception.Message)
}

try {
    . ".\scripts\identity\AIOfficeIdentity.Common.ps1"

    $Envelope = New-AIOfficeIdentityEnvelope `
        -MessageType "identity_test" `
        -Payload ([ordered]@{ test = $true }) `
        -SourceComponent "Identity System" `
        -TargetComponent "Validation Suite"

    if ([string]$Envelope.office_version -ne "1.1.1" -or
        [string]$Envelope.message_type -ne "identity_test") {
        throw "Identity envelope did not contain expected values."
    }

    Write-Host (
        "[ENVELOPE OK] " +
        [string]$Envelope.correlation_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[ENVELOPE ER] Identity envelope test failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Identity envelope failed: " + $_.Exception.Message)
}

try {
    $ExportPath = & ".\scripts\identity\Export-AIOfficeIdentity.ps1"

    if (-not (Test-Path -LiteralPath $ExportPath -PathType Leaf)) {
        throw "Identity export file was not created."
    }

    Get-Content -LiteralPath $ExportPath -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host (
        "[EXPORT OK  ] " +
        [string]$ExportPath
    ) -ForegroundColor Green
}
catch {
    Write-Host "[EXPORT ERR ] Identity export failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $Errors.Add("Identity export failed: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " identity system error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.1 Identity System checks passed." `
    -ForegroundColor Green
