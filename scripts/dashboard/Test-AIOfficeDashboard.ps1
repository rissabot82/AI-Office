param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Errors = New-Object System.Collections.Generic.List[string]

$Files = @(
    ".\config\dashboard\dashboard-config.json",
    ".\dashboard\public\index.html",
    ".\dashboard\public\styles.css",
    ".\dashboard\public\app.js",
    ".\scripts\dashboard\Start-AIOfficeDashboardServer.ps1",
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1"
)

foreach ($File in $Files) {
    if (Test-Path -LiteralPath $File -PathType Leaf) {
        Write-Host "[FOUND] $File" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $File" -ForegroundColor Red
        $Errors.Add("Missing: $File")
    }
}

try {
    Get-Content `
        -LiteralPath ".\config\dashboard\dashboard-config.json" `
        -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] dashboard-config.json" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

foreach ($Script in @(
    ".\scripts\dashboard\Start-AIOfficeDashboardServer.ps1",
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Stop-AIOfficeDashboard.ps1",
    ".\scripts\dashboard\Install-AIOfficeDashboardTask.ps1"
)) {
    $Tokens = $null
    $ParseErrors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path $Script),
        [ref]$Tokens,
        [ref]$ParseErrors
    ) | Out-Null

    if ($ParseErrors.Count -eq 0) {
        Write-Host "[SYNTAX OK] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add(
            $Script + ": " +
            (($ParseErrors | ForEach-Object { $_.Message }) -join "; ")
        )
    }
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) dashboard validation error(s) found." `
        -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "AI Office Dashboard validation passed." -ForegroundColor Green
