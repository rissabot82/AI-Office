param()

$ErrorActionPreference = "Stop"

$PublicRoot = "E:\AI\AI-Office\dashboard\public"
$HtmlPath = Join-Path $PublicRoot "index.html"

if (-not (Test-Path -LiteralPath $HtmlPath -PathType Leaf)) {
    throw "Dashboard entry point not found: $HtmlPath"
}

Write-Host "Dashboard entry point: $HtmlPath" -ForegroundColor Cyan

$Html = Get-Content -LiteralPath $HtmlPath -Raw

$CssTag = '<link rel="stylesheet" href="/autonomous-enterprise-module.css">'
$JsTag = '<script src="/autonomous-enterprise-module.js"></script>'
$ModuleMarkup = '<div id="autonomous-enterprise-module" data-ai-office-module="autonomous-enterprise"></div>'

if ($Html -notmatch [regex]::Escape($CssTag)) {
    if ($Html -match '</head>') {
        $Html = $Html -replace '</head>', ($CssTag + [Environment]::NewLine + '</head>')
    }
    else {
        $Html = $CssTag + [Environment]::NewLine + $Html
    }
}

if ($Html -notmatch 'id=["'']autonomous-enterprise-module["'']') {
    if ($Html -match '</body>') {
        $Html = $Html -replace '</body>', ($ModuleMarkup + [Environment]::NewLine + '</body>')
    }
    else {
        $Html += [Environment]::NewLine + $ModuleMarkup
    }
}

if ($Html -notmatch [regex]::Escape($JsTag)) {
    if ($Html -match '</body>') {
        $Html = $Html -replace '</body>', ($JsTag + [Environment]::NewLine + '</body>')
    }
    else {
        $Html += [Environment]::NewLine + $JsTag
    }
}

Set-Content -LiteralPath $HtmlPath -Value $Html -Encoding UTF8

Write-Host "Autonomous AI Enterprise dashboard integration installed." -ForegroundColor Green
