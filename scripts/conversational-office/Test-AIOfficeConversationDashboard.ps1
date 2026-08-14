param()

$ErrorActionPreference = "Stop"

$Snapshot = & "E:\AI\AI-Office\scripts\conversational-office\New-AIOfficeConversationDashboardSnapshot.ps1"

$Required = @(
    "E:\AI\AI-Office\dashboard\public\data\conversational-office.json",
    "E:\AI\AI-Office\dashboard\public\conversational-office-module.js",
    "E:\AI\AI-Office\dashboard\public\conversational-office-module.css",
    "E:\AI\AI-Office\dashboard\public\index.html"
)

foreach ($Path in $Required) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Conversation dashboard component missing: $Path"
    }
}

$Html = Get-Content -LiteralPath "E:\AI\AI-Office\dashboard\public\index.html" -Raw

if ($Html -notmatch 'conversational-office-module') {
    throw "Conversation dashboard integration is missing."
}

Write-Host "[SNAPSHOT OK] Conversational dashboard data generated." -ForegroundColor Green
Write-Host "[DASHBOARD OK] Conversational dashboard integration passed." -ForegroundColor Green

return $Snapshot
