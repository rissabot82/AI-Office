param()

$ErrorActionPreference = "Stop"

$DashboardRoot = "E:\AI\AI-Office\dashboard"
$PublicRoot = Join-Path $DashboardRoot "public"

$HtmlCandidates = @(
    @(
        (Join-Path $PublicRoot "index.html")
        (Join-Path $DashboardRoot "index.html")
    ) | Where-Object {
        Test-Path -LiteralPath $_ -PathType Leaf
    }
)

if ($HtmlCandidates.Count -eq 0) {
    Write-Host "Dashboard HTML entry point not found. Module files remain available for manual dashboard loading." -ForegroundColor Yellow

    return [pscustomobject]@{
        integrated = $false
        reason = "html_entry_not_found"
    }
}

$HtmlPath = [string]$HtmlCandidates[0]

Write-Host "Dashboard entry point: $HtmlPath" -ForegroundColor Cyan

$Html = Get-Content -LiteralPath $HtmlPath -Raw
$Changed = $false

if ($Html -notmatch 'operations-integrations-module\.css') {

    $CssTag = '<link rel="stylesheet" href="/operations-integrations-module.css">'

    if ($Html -match '</head>') {
        $Html = $Html -replace '</head>', ($CssTag + "`r`n</head>")
        $Changed = $true
    }
}

if ($Html -notmatch 'data-ai-office-operations-integrations') {

    $ModuleHost = '<div id="operations-integrations-module" data-ai-office-operations-integrations></div>'

    if ($Html -match '</main>') {
        $Html = $Html -replace '</main>', ($ModuleHost + "`r`n</main>")
        $Changed = $true
    }
    elseif ($Html -match '</body>') {
        $Html = $Html -replace '</body>', ($ModuleHost + "`r`n</body>")
        $Changed = $true
    }
}

if ($Html -notmatch 'operations-integrations-module\.js') {

    $JsTag = '<script src="/operations-integrations-module.js"></script>'

    if ($Html -match '</body>') {
        $Html = $Html -replace '</body>', ($JsTag + "`r`n</body>")
        $Changed = $true
    }
}

if ($Changed) {

    Set-Content `
        -LiteralPath $HtmlPath `
        -Value $Html `
        -Encoding UTF8

    Write-Host "Operations and Integrations dashboard integration installed." -ForegroundColor Green
}
else {
    Write-Host "Operations and Integrations dashboard integration already present." -ForegroundColor Yellow
}

return [pscustomobject]@{
    integrated = $true
    html_path = $HtmlPath
    changed = $Changed
}

