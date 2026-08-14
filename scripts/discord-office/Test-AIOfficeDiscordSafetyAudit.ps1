param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.4 Part G Discord Safety and Audit..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]
$TestAuditPath = $null

try {
    Get-Content ".\config\discord-office\safety-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\discord-office\safety-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid safety policy JSON.")
}

$Scripts = @(
    ".\scripts\discord-office\Write-AIOfficeDiscordAuditEvent.ps1",
    ".\scripts\discord-office\Get-AIOfficeDiscordAudit.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordSafety.ps1",
    ".\scripts\discord-office\Get-AIOfficeDiscordSafetyStatus.ps1",
    ".\scripts\discord-office\Invoke-AIOfficeDiscordSafetyCommand.ps1",
    ".\scripts\discord-office\Test-AIOfficeDiscordSafetyAudit.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $Status = & ".\scripts\discord-office\Get-AIOfficeDiscordSafetyStatus.ps1"

    if (-not [bool]$Status.require_allowlist) {
        throw "Allowlist protection is not required by policy."
    }

    Write-Host "[ALLOWLIST POLICY OK]" -ForegroundColor Green

    $Audit = & ".\scripts\discord-office\Write-AIOfficeDiscordAuditEvent.ps1" `
        -EventType "certification_test" `
        -DiscordUserId "PARTG-USER" `
        -DiscordGuildId "PARTG-GUILD" `
        -DiscordChannelId "PARTG-CHANNEL" `
        -Department "chief-of-staff" `
        -Outcome "passed" `
        -Details "token=THIS_VALUE_SHOULD_BE_REDACTED_1234567890"

    $TestAuditPath = "E:\AI\AI-Office\workspace\discord-office\audit\$($Audit.audit_id).json"

    if (-not (Test-Path -LiteralPath $TestAuditPath)) {
        throw "Audit event was not persisted."
    }

    $RawAudit = Get-Content -LiteralPath $TestAuditPath -Raw

    if ($RawAudit.Contains("THIS_VALUE_SHOULD_BE_REDACTED_1234567890")) {
        throw "Token-like audit value was not redacted."
    }

    Write-Host "[AUDIT REDACTION OK]" -ForegroundColor Green

    $Security = & ".\scripts\discord-office\Invoke-AIOfficeDiscordSafetyCommand.ps1" -CommandText "/security"

    if (-not [bool]$Security.handled) {
        throw "/security command was not handled."
    }

    Write-Host "[SECURITY COMMAND OK]" -ForegroundColor Green

    $AuditCommand = & ".\scripts\discord-office\Invoke-AIOfficeDiscordSafetyCommand.ps1" -CommandText "/audit 3"

    if (-not [bool]$AuditCommand.handled) {
        throw "/audit command was not handled."
    }

    Write-Host "[AUDIT COMMAND OK]" -ForegroundColor Green
}
catch {
    Write-Host "[SAFETY ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}
finally {
    if ($TestAuditPath) {
        Remove-Item -LiteralPath $TestAuditPath -Force -ErrorAction SilentlyContinue
    }
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Discord Safety and Audit error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v2.4 Part G Discord Safety and Audit checks passed." -ForegroundColor Green
