param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$HtmlPath = "E:\AI\AI-Office\dashboard\public\index.html"
$CssPath = "E:\AI\AI-Office\dashboard\public\styles.css"
$AppPath = "E:\AI\AI-Office\dashboard\public\app.js"

$Html = Get-Content -LiteralPath $HtmlPath -Raw

if ($Html -notmatch "knowledge-graph-module\.css") {
    $Html = $Html.Replace(
        '<link rel="stylesheet" href="/styles.css">',
        '<link rel="stylesheet" href="/styles.css">' + [Environment]::NewLine +
        '  <link rel="stylesheet" href="/knowledge-graph-module.css">'
    )
}

if ($Html -notmatch "knowledge-graph-module\.js") {
    $Html = $Html.Replace(
        '<script src="/app.js"></script>',
        '<script src="/app.js"></script>' + [Environment]::NewLine +
        '  <script src="/knowledge-graph-module.js"></script>'
    )
}

Set-Content -LiteralPath $HtmlPath -Value $Html -Encoding UTF8

& "E:\AI\AI-Office\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphDashboardSnapshot.ps1" |
    Out-Null

Write-Host "Knowledge Graph dashboard integration installed." -ForegroundColor Green
