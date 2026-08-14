param(
    [switch]$SkipLiveApi
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part B Live Discord Intake..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\discord-office\live-runtime-policy.json",
    ".\config\discord-office\discord-connection-schema.json",
    ".\workspace\templates\discord-connection-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\discord-office\AIOfficeDiscordRuntime.Common.ps1",
    ".\scripts\discord-office\Initialize-AIOfficeDiscordConnection.ps1",
    ".\scripts\discord-office\Set-AIOfficeDiscordAllowlist.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordInboundMessage.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordLiveRuntime.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING SCRIPT] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $TokenName = [string](Get-Content ".\config\discord-office\discord-policy.json" -Raw | ConvertFrom-Json).security.token_environment_variable
    $Token = [Environment]::GetEnvironmentVariable($TokenName, "User")

    if ([string]::IsNullOrWhiteSpace($Token)) {
        Write-Host "[TOKEN PENDING] $TokenName is not configured yet." -ForegroundColor Yellow
    }
    else {
        Write-Host "[TOKEN OK] Discord bot token environment variable is configured." -ForegroundColor Green
    }

    if (-not $SkipLiveApi -and -not [string]::IsNullOrWhiteSpace($Token)) {
        $Connection = & ".\scripts\discord-office\Initialize-AIOfficeDiscordConnection.ps1"

        if ([string]$Connection.status -ne "connected") {
            throw "Discord API connection did not report connected."
        }

        Write-Host "[DISCORD API OK] $($Connection.bot_username)" -ForegroundColor Green
    }
    elseif ($SkipLiveApi) {
        Write-Host "[LIVE API SKIPPED] Structural runtime test only." -ForegroundColor Yellow
    }
    else {
        Write-Host "[LIVE API PENDING] Configure token before live connection certification." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[LIVE RUNTIME ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Live Discord Intake error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part B Live Discord Intake structural checks passed." -ForegroundColor Green
