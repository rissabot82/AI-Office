param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$HtmlPath = "E:\AI\AI-Office\dashboard\public\index.html"
$Html = Get-Content -LiteralPath $HtmlPath -Raw

if ($Html -notmatch "multi-agent-module\.css") {
    $Html = $Html.Replace(
        '<link rel="stylesheet" href="/styles.css">',
        '<link rel="stylesheet" href="/styles.css">' +
        [Environment]::NewLine +
        '  <link rel="stylesheet" href="/multi-agent-module.css">'
    )
}

if ($Html -notmatch "multi-agent-module\.js") {
    $Html = $Html.Replace(
        '<script src="/app.js"></script>',
        '<script src="/app.js"></script>' +
        [Environment]::NewLine +
        '  <script src="/multi-agent-module.js"></script>'
    )
}

Set-Content -LiteralPath $HtmlPath -Value $Html -Encoding UTF8

& "E:\AI\AI-Office\scripts\multi-agent\New-AIOfficeMultiAgentDashboardSnapshot.ps1" |
    Out-Null

Write-Host "Multi-Agent dashboard integration installed." -ForegroundColor Green
