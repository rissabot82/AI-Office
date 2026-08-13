param()

$ErrorActionPreference = "Stop"

$HtmlPath = "E:\AI\AI-Office\dashboard\public\index.html"

if (-not (Test-Path -LiteralPath $HtmlPath -PathType Leaf)) {
    throw "Dashboard entry point not found: $HtmlPath"
}

$Html = Get-Content -LiteralPath $HtmlPath -Raw

$CssTag = '<link rel="stylesheet" href="/self-hosting-final-module.css">'
$JsTag = '<script src="/self-hosting-final-module.js"></script>'
$HostMarkup = '<div id="self-hosting-final-module" data-ai-office-module="self-hosting-final"></div>'

if ($Html -notmatch 'self-hosting-final-module\.css') {
    $Html = if ($Html -match '</head>') {
        $Html -replace '</head>', ($CssTag + [Environment]::NewLine + '</head>')
    } else {
        $CssTag + [Environment]::NewLine + $Html
    }
}

if ($Html -notmatch 'id=["'']self-hosting-final-module["'']') {
    $Html = if ($Html -match '</body>') {
        $Html -replace '</body>', ($HostMarkup + [Environment]::NewLine + '</body>')
    } else {
        $Html + [Environment]::NewLine + $HostMarkup
    }
}

if ($Html -notmatch 'self-hosting-final-module\.js') {
    $Html = if ($Html -match '</body>') {
        $Html -replace '</body>', ($JsTag + [Environment]::NewLine + '</body>')
    } else {
        $Html + [Environment]::NewLine + $JsTag
    }
}

Set-Content -LiteralPath $HtmlPath -Value $Html -Encoding UTF8
Write-Host "Self-Hosted AI Office final dashboard integration installed." -ForegroundColor Green
