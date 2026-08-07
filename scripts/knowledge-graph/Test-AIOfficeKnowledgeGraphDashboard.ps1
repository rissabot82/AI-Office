param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($File in @(
    "E:\AI\AI-Office\dashboard\public\knowledge-graph-module.js",
    "E:\AI\AI-Office\dashboard\public\knowledge-graph-module.css",
    "E:\AI\AI-Office\dashboard\public\knowledge-graph-status.json"
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

if ($Html -match "knowledge-graph-module\.js") {
    Write-Host "[HTML OK] Knowledge Graph JS linked." -ForegroundColor Green
}
else {
    $Errors.Add("Knowledge Graph JS is not linked in index.html.")
}

if ($Html -match "knowledge-graph-module\.css") {
    Write-Host "[HTML OK] Knowledge Graph CSS linked." -ForegroundColor Green
}
else {
    $Errors.Add("Knowledge Graph CSS is not linked in index.html.")
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) dashboard integration error(s) found." `
        -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "AI Office v1.5 Knowledge Graph dashboard integration passed." `
    -ForegroundColor Green
