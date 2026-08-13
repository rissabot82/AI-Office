param()

$ErrorActionPreference = "Stop"
$HtmlPath = "E:\AI\AI-Office\dashboard\public\index.html"

if (-not (Test-Path -LiteralPath $HtmlPath -PathType Leaf)) {
    throw "Dashboard entry point not found: $HtmlPath"
}

Write-Host "Dashboard entry point: $HtmlPath" -ForegroundColor Cyan

$Html = Get-Content -LiteralPath $HtmlPath -Raw
$CssTag = '<link rel="stylesheet" href="/self-hosting-module.css">'
$JsTag = '<script src="/self-hosting-module.js"></script>'
$ModuleMarkup = '<div id="self-hosting-module" data-ai-office-module="self-hosting"></div>'

if ($Html -notmatch 'self-hosting-module\.css') {
    $Html = if ($Html -match '</head>') { $Html -replace '</head>', ($CssTag + [Environment]::NewLine + '</head>') } else { $CssTag + [Environment]::NewLine + $Html }
}
if ($Html -notmatch 'id=["'']self-hosting-module["'']') {
    $Html = if ($Html -match '</body>') { $Html -replace '</body>', ($ModuleMarkup + [Environment]::NewLine + '</body>') } else { $Html + [Environment]::NewLine + $ModuleMarkup }
}
if ($Html -notmatch 'self-hosting-module\.js') {
    $Html = if ($Html -match '</body>') { $Html -replace '</body>', ($JsTag + [Environment]::NewLine + '</body>') } else { $Html + [Environment]::NewLine + $JsTag }
}

Set-Content -LiteralPath $HtmlPath -Value $Html -Encoding UTF8
Write-Host "Self-Hosting dashboard integration installed." -ForegroundColor Green
