param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$PublicDirectory = "E:\AI\AI-Office\dashboard\public"

if (-not (Test-Path -LiteralPath $PublicDirectory -PathType Container)) {
    throw "Dashboard public directory not found: $PublicDirectory"
}

$HtmlFiles = @(
    Get-ChildItem -LiteralPath $PublicDirectory -Filter "*.html" -File -ErrorAction SilentlyContinue
)

if ($HtmlFiles.Count -eq 0) {
    Write-Host "No dashboard HTML file found. Module assets are installed and snapshot generation remains available." -ForegroundColor Yellow
    exit 0
}

$Target = $HtmlFiles |
    Sort-Object `
        @{ Expression = { if ($_.Name -eq "index.html") { 0 } else { 1 } }; Descending = $false },
        @{ Expression = { $_.Name }; Descending = $false } |
    Select-Object -First 1

$Content = Get-Content -LiteralPath $Target.FullName -Raw

if ($Content -notlike "*business-incubator-module.css*") {
    if ($Content -match "</head>") {
        $Content = $Content -replace "</head>", '    <link rel="stylesheet" href="/business-incubator-module.css">`r`n</head>'
    }
}

if ($Content -notlike "*data-ai-office-business-incubator*") {
    if ($Content -match "</body>") {
        $Content = $Content -replace "</body>", '    <div id="business-incubator-module" data-ai-office-business-incubator></div>`r`n    <script src="/business-incubator-module.js"></script>`r`n</body>'
    }
}

Set-Content -LiteralPath $Target.FullName -Value $Content -Encoding UTF8
Write-Host "Business Incubator dashboard integration installed: $($Target.Name)" -ForegroundColor Green
