param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($File in @(
    "E:\AI\AI-Office\dashboard\public\financial-office-module.js",
    "E:\AI\AI-Office\dashboard\public\financial-office-module.css",
    "E:\AI\AI-Office\dashboard\public\financial-office-status.json"
)) {
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        Write-Host "[FOUND] $File" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $File" -ForegroundColor Red
        $Errors.Add("Missing: $File")
    }
}

$Html = Get-Content `
    -LiteralPath "E:\AI\AI-Office\dashboard\public\index.html" `
    -Raw

if ($Html -match "financial-office-module\.js") {
    Write-Host "[HTML OK] Financial Office JS linked." -ForegroundColor Green
}
else {
    $Errors.Add("Financial Office JS is not linked in index.html.")
}

if ($Html -match "financial-office-module\.css") {
    Write-Host "[HTML OK] Financial Office CSS linked." -ForegroundColor Green
}
else {
    $Errors.Add("Financial Office CSS is not linked in index.html.")
}

try {
    Get-Content `
        -LiteralPath "E:\AI\AI-Office\dashboard\public\financial-office-status.json" `
        -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[JSON OK] Financial Office dashboard snapshot valid." -ForegroundColor Green
}
catch {
    $Errors.Add("Financial Office dashboard snapshot is invalid JSON.")
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Financial Office dashboard integration error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "AI Office v1.7 Financial Office dashboard integration passed." -ForegroundColor Green
