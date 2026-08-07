param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($File in @(
    "E:\AI\AI-Office\dashboard\public\multi-agent-module.js",
    "E:\AI\AI-Office\dashboard\public\multi-agent-module.css",
    "E:\AI\AI-Office\dashboard\public\multi-agent-status.json"
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

if ($Html -match "multi-agent-module\.js") {
    Write-Host "[HTML OK] Multi-Agent JS linked." -ForegroundColor Green
}
else {
    $Errors.Add("Multi-Agent JS is not linked in index.html.")
}

if ($Html -match "multi-agent-module\.css") {
    Write-Host "[HTML OK] Multi-Agent CSS linked." -ForegroundColor Green
}
else {
    $Errors.Add("Multi-Agent CSS is not linked in index.html.")
}

try {
    Get-Content `
        -LiteralPath "E:\AI\AI-Office\dashboard\public\multi-agent-status.json" `
        -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[JSON OK] Multi-Agent dashboard snapshot valid." -ForegroundColor Green
}
catch {
    $Errors.Add("Multi-Agent dashboard snapshot is invalid JSON.")
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) dashboard integration error(s) found." `
        -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "AI Office v1.6 Multi-Agent dashboard integration passed." `
    -ForegroundColor Green
