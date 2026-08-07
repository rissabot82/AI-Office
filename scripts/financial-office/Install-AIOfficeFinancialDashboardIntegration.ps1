param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$HtmlPath = "E:\AI\AI-Office\dashboard\public\index.html"
$Html = Get-Content -LiteralPath $HtmlPath -Raw

if ($Html -notmatch "financial-office-module\.css") {
    $Html = $Html.Replace(
        '<link rel="stylesheet" href="/styles.css">',
        '<link rel="stylesheet" href="/styles.css">' +
        [Environment]::NewLine +
        '  <link rel="stylesheet" href="/financial-office-module.css">'
    )
}

if ($Html -notmatch "financial-office-module\.js") {
    $Html = $Html.Replace(
        '<script src="/app.js"></script>',
        '<script src="/app.js"></script>' +
        [Environment]::NewLine +
        '  <script src="/financial-office-module.js"></script>'
    )
}

Set-Content -LiteralPath $HtmlPath -Value $Html -Encoding UTF8

& "E:\AI\AI-Office\scripts\financial-office\New-AIOfficeFinancialDashboardSnapshot.ps1" |
    Out-Null

Write-Host "Financial Office dashboard integration installed." -ForegroundColor Green
