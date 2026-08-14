param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part D Department and Agent Routing..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    Get-Content ".\config\discord-office\routing-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\discord-office\routing-policy.json" -ForegroundColor Green
}
catch { $Errors.Add("Invalid routing policy JSON.") }

$Scripts = @(
    ".\scripts\discord-office\Get-AIOfficeDiscordRoutingPolicy.ps1",
    ".\scripts\discord-office\Resolve-AIOfficeDiscordDepartment.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordRoutedTurn.ps1",
    ".\scripts\discord-office\Get-AIOfficeDiscordDepartments.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordCommand.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordInboundMessage.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path $Script) { Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green }
    else { $Errors.Add("Missing script: $Script") }
}

try {
    $Default = & ".\scripts\discord-office\Resolve-AIOfficeDiscordDepartment.ps1" -Content "Prepare my morning priorities."
    if ([string]$Default.department -ne "chief-of-staff") { throw "Default route is not Chief of Staff." }
    Write-Host "[DEFAULT ROUTE OK] chief-of-staff" -ForegroundColor Green

    $Explicit = & ".\scripts\discord-office\Resolve-AIOfficeDiscordDepartment.ps1" `
        -Content "/department marketing Draft a campaign concept."

    if ([string]$Explicit.department -ne "marketing") { throw "Explicit marketing route failed." }
    if ([string]$Explicit.content -ne "Draft a campaign concept.") { throw "Explicit routed content parsing failed." }
    Write-Host "[EXPLICIT ROUTE OK] marketing" -ForegroundColor Green

    $Alias = & ".\scripts\discord-office\Resolve-AIOfficeDiscordDepartment.ps1" `
        -Content "Check this tag." `
        -RequestedDepartment "ga4"

    if ([string]$Alias.department -ne "analytics") { throw "Department alias resolution failed." }
    Write-Host "[ALIAS ROUTE OK] ga4 -> analytics" -ForegroundColor Green

    $Departments = & ".\scripts\discord-office\Get-AIOfficeDiscordDepartments.ps1"
    if (@($Departments).Count -lt 5) { throw "Department registry appears incomplete." }
    Write-Host "[DEPARTMENT REGISTRY OK] $(@($Departments).Count) departments" -ForegroundColor Green

    $Help = & ".\scripts\discord-office\Invoke-AIOfficeDiscordCommand.ps1" `
        -CommandText "/help" `
        -DiscordUserId "CERT" `
        -DiscordGuildId "CERT" `
        -DiscordChannelId "CERT"

    if (-not ([string]$Help.response).Contains("/department")) { throw "Routing commands missing from help." }
    Write-Host "[COMMAND INTEGRATION OK]" -ForegroundColor Green
}
catch {
    Write-Host "[ROUTING ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Department Routing error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part D Department and Agent Routing checks passed." -ForegroundColor Green
