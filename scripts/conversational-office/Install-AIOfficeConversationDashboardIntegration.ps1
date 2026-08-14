param()

$ErrorActionPreference = "Stop"

$HtmlPath = "E:\AI\AI-Office\dashboard\public\index.html"

if (-not (Test-Path -LiteralPath $HtmlPath -PathType Leaf)) {
    throw "Dashboard entry point not found: $HtmlPath"
}

$Html = Get-Content -LiteralPath $HtmlPath -Raw

$CssTag = '<link rel="stylesheet" href="/conversational-office-module.css">'
$JsTag = '<script src="/conversational-office-module.js"></script>'
$HostMarkup = '<div id="conversational-office-module" data-ai-office-module="conversational-office"></div>'

if ($Html -notmatch 'conversational-office-module\.css') {
    $Html = if ($Html -match '</head>') {
        $Html -replace '</head>', ($CssTag + [Environment]::NewLine + '</head>')
    } else {
        $CssTag + [Environment]::NewLine + $Html
    }
}

if ($Html -notmatch 'id=["'']conversational-office-module["'']') {
    $Html = if ($Html -match '</body>') {
        $Html -replace '</body>', ($HostMarkup + [Environment]::NewLine + '</body>')
    } else {
        $Html + [Environment]::NewLine + $HostMarkup
    }
}

if ($Html -notmatch 'conversational-office-module\.js') {
    $Html = if ($Html -match '</body>') {
        $Html -replace '</body>', ($JsTag + [Environment]::NewLine + '</body>')
    } else {
        $Html + [Environment]::NewLine + $JsTag
    }
}

Set-Content -LiteralPath $HtmlPath -Value $Html -Encoding UTF8
Write-Host "Conversational AI Office dashboard integration installed." -ForegroundColor Green
