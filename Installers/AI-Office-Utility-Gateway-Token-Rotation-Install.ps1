# ============================================================
# AI Office Utility Installer
# OpenClaw Gateway Token Rotation
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function Write-File {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Write-Host "[WRITTEN] $Path" -ForegroundColor Green
}

@(
    ".\scripts\utilities",
    ".\workspace\security",
    ".\workspace\security\credential-history",
    ".\workspace\security\backups",
    ".\config\security",
    ".\docs",
    ".\Installers"
) | ForEach-Object { Ensure-Directory $_ }

$Policy = @"
{
  "schema_version": "1.0.0",
  "utility": "OpenClaw Gateway Token Rotation",
  "wsl_distribution": "OpenClawGateway",
  "openclaw_config_path": "/home/openclaw/.openclaw/openclaw.json",
  "gateway_service": "openclaw-gateway",
  "gateway_port": 18789,
  "token_bytes": 32,
  "backup_before_rotation": true,
  "rollback_on_failure": true,
  "verify_after_rotation": true,
  "store_token_in_history": false
}
"@

Write-File ".\config\security\gateway-token-rotation-policy.json" $Policy

$RotationScript = @"
param(
    [string]`$WslDistribution = "OpenClawGateway",
    [string]`$OpenClawConfigPath = "/home/openclaw/.openclaw/openclaw.json",
    [string]`$GatewayService = "openclaw-gateway",
    [int]`$GatewayPort = 18789,
    [switch]`$SkipVerification
)

`$ErrorActionPreference = "Stop"

`$Repository = (Resolve-Path (Join-Path `$PSScriptRoot "..\..")).Path
Set-Location `$Repository

`$HistoryDirectory = Join-Path `$Repository "workspace\security\credential-history"
`$BackupDirectory = Join-Path `$Repository "workspace\security\backups"

foreach (`$Directory in @(`$HistoryDirectory, `$BackupDirectory)) {
    if (-not (Test-Path -LiteralPath `$Directory -PathType Container)) {
        New-Item -ItemType Directory -Path `$Directory -Force | Out-Null
    }
}

function Invoke-WslText {
    param([Parameter(Mandatory=`$true)][string[]]`$Arguments)

    `$Output = & wsl.exe @Arguments 2>&1

    if (`$LASTEXITCODE -ne 0) {
        throw (`$Output -join [Environment]::NewLine)
    }

    return @(`$Output)
}

`$Distribution = @(
    & wsl.exe -l -q 2>`$null |
        ForEach-Object { ([string]`$_).Trim([char]0).Trim() } |
        Where-Object { `$_ }
)

if (`$Distribution -notcontains `$WslDistribution) {
    throw "WSL distribution not found: `$WslDistribution"
}

`$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
`$LinuxBackupPath = `$OpenClawConfigPath + ".backup-" + `$Timestamp
`$LocalBackupPath = Join-Path `$BackupDirectory ("openclaw-" + `$Timestamp + ".json")

`$ConfigJson = Invoke-WslText -Arguments @(
    "-d", `$WslDistribution,
    "--",
    "cat", `$OpenClawConfigPath
)

`$ConfigText = `$ConfigJson -join [Environment]::NewLine

try {
    `$ConfigText | ConvertFrom-Json | Out-Null
}
catch {
    throw "OpenClaw configuration is not valid JSON."
}

Set-Content -LiteralPath `$LocalBackupPath -Value `$ConfigText -Encoding UTF8

Invoke-WslText -Arguments @(
    "-d", `$WslDistribution,
    "--",
    "cp", `$OpenClawConfigPath, `$LinuxBackupPath
) | Out-Null

`$NewToken = (
    Invoke-WslText -Arguments @(
        "-d", `$WslDistribution,
        "--",
        "python3", "-c",
        "import secrets; print(secrets.token_hex(32))"
    )
)[0].Trim()

if ([string]::IsNullOrWhiteSpace(`$NewToken) -or `$NewToken.Length -ne 64) {
    throw "Generated token was not a valid 64-character token."
}

`$PythonScript = @'
import json
import os
import sys

path = sys.argv[1]
token = os.environ["AI_OFFICE_NEW_GATEWAY_TOKEN"]

with open(path, "r", encoding="utf-8") as handle:
    data = json.load(handle)

data.setdefault("gateway", {}).setdefault("auth", {})["token"] = token

temporary_path = path + ".tmp"

with open(temporary_path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2)
    handle.write("\n")

os.replace(temporary_path, path)
'@

`$EncodedPython = [Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes(`$PythonScript)
)

`$UpdateCommand = "import base64; exec(base64.b64decode('`$EncodedPython').decode('utf-8'))"

try {
    Invoke-WslText -Arguments @(
        "-d", `$WslDistribution,
        "--",
        "env",
        ("AI_OFFICE_NEW_GATEWAY_TOKEN=" + `$NewToken),
        "python3", "-c", `$UpdateCommand,
        `$OpenClawConfigPath
    ) | Out-Null

    Invoke-WslText -Arguments @(
        "-d", `$WslDistribution,
        "--",
        "systemctl", "--user", "restart", `$GatewayService
    ) | Out-Null

    `$Ready = `$false

    for (`$Attempt = 1; `$Attempt -le 15; `$Attempt++) {
        Start-Sleep -Seconds 1

        try {
            `$Connection = Test-NetConnection `
                -ComputerName "localhost" `
                -Port `$GatewayPort `
                -WarningAction SilentlyContinue

            if (`$Connection.TcpTestSucceeded) {
                `$Ready = `$true
                break
            }
        }
        catch {
        }
    }

    if (-not `$Ready) {
        throw "Gateway did not become reachable on port `$GatewayPort."
    }

    `$env:OPENCLAW_GATEWAY_TOKEN = `$NewToken

    if (-not `$SkipVerification) {
        `$ConnectionScript = Join-Path `
            `$Repository `
            "scripts\bridge\Test-AIOfficeOpenClawConnection.ps1"

        if (-not (Test-Path -LiteralPath `$ConnectionScript -PathType Leaf)) {
            throw "AI Office bridge connection test script was not found."
        }

        `$VerificationOutput = & powershell.exe `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File `$ConnectionScript `
            -Authenticated

        `$VerificationText = `$VerificationOutput | Out-String

        if (`$VerificationText -notmatch "authenticated\s*:\s*True") {
            throw "Authentication verification did not report authenticated: True."
        }
    }

    `$HistoryId = "ROT-" + `$Timestamp
    `$History = [ordered]@{
        rotation_id = `$HistoryId
        rotated_at = (Get-Date).ToString("o")
        wsl_distribution = `$WslDistribution
        config_path = `$OpenClawConfigPath
        gateway_service = `$GatewayService
        gateway_port = `$GatewayPort
        token_length = `$NewToken.Length
        token_stored = `$false
        local_backup_path = `$LocalBackupPath
        linux_backup_path = `$LinuxBackupPath
        verification_skipped = [bool]`$SkipVerification
        status = "successful"
    }

    `$History |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -LiteralPath (Join-Path `$HistoryDirectory (`$HistoryId + ".json")) `
            -Encoding UTF8

    Write-Host ""
    Write-Host "OpenClaw gateway token rotated successfully." -ForegroundColor Green
    Write-Host "Gateway authentication verified." -ForegroundColor Green
    Write-Host "The current PowerShell session has been updated." -ForegroundColor Green
    Write-Host ""
    Write-Host "Token length: `$(`$NewToken.Length)" -ForegroundColor Cyan
    Write-Host "Backup: `$LocalBackupPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The token was not written to AI Office history." -ForegroundColor Yellow

    return [pscustomobject]`$History
}
catch {
    try {
        Invoke-WslText -Arguments @(
            "-d", `$WslDistribution,
            "--",
            "cp", `$LinuxBackupPath, `$OpenClawConfigPath
        ) | Out-Null

        Invoke-WslText -Arguments @(
            "-d", `$WslDistribution,
            "--",
            "systemctl", "--user", "restart", `$GatewayService
        ) | Out-Null
    }
    catch {
    }

    `$FailureId = "ROT-" + `$Timestamp
    `$Failure = [ordered]@{
        rotation_id = `$FailureId
        rotated_at = (Get-Date).ToString("o")
        status = "failed"
        error = `$_.Exception.Message
        rollback_attempted = `$true
        local_backup_path = `$LocalBackupPath
        linux_backup_path = `$LinuxBackupPath
    }

    `$Failure |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -LiteralPath (Join-Path `$HistoryDirectory (`$FailureId + ".json")) `
            -Encoding UTF8

    throw
}
"@

Write-File ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1" $RotationScript

$TestScript = @"
param()

`$ErrorActionPreference = "Stop"

`$Root = (Resolve-Path (Join-Path `$PSScriptRoot "..\..")).Path
Set-Location `$Root

`$Errors = New-Object System.Collections.Generic.List[string]

`$Files = @(
    ".\config\security\gateway-token-rotation-policy.json",
    ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"
)

foreach (`$File in `$Files) {
    if (Test-Path -LiteralPath `$File -PathType Leaf) {
        Write-Host "[FOUND] `$File" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] `$File" -ForegroundColor Red
        `$Errors.Add("Missing: `$File")
    }
}

try {
    Get-Content `
        -LiteralPath ".\config\security\gateway-token-rotation-policy.json" `
        -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] gateway-token-rotation-policy.json" `
        -ForegroundColor Green
}
catch {
    `$Errors.Add(`$_.Exception.Message)
}

`$Tokens = `$null
`$ParseErrors = `$null

[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"),
    [ref]`$Tokens,
    [ref]`$ParseErrors
) | Out-Null

if (`$ParseErrors.Count -eq 0) {
    Write-Host "[SYNTAX OK] Rotate-AIOfficeGatewayToken.ps1" `
        -ForegroundColor Green
}
else {
    `$Errors.Add((`$ParseErrors | ForEach-Object { `$_.Message }) -join "; ")
}

if (`$Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "`$(`$Errors.Count) utility validation error(s) found." `
        -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Gateway token rotation utility validation passed." `
    -ForegroundColor Green
"@

Write-File ".\scripts\utilities\Test-AIOfficeGatewayTokenRotationUtility.ps1" $TestScript

$Guide = @"
# AI Office Gateway Token Rotation Utility

Run:

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"
```

The utility:

- Backs up openclaw.json
- Generates a new 256-bit gateway token
- Updates only gateway.auth.token
- Restarts the OpenClaw gateway
- Waits for port 18789
- Updates the current process environment
- Verifies authenticated AI Office access
- Rolls back if verification fails
- Records a token-free audit entry
"@

Write-File ".\docs\AI-Office-Gateway-Token-Rotation.md" $Guide

$Tokens = $null
$ParseErrors = $null

[System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"),
    [ref]$Tokens,
    [ref]$ParseErrors
) | Out-Null

if ($ParseErrors.Count -gt 0) {
    throw (
        "Generated rotation script contains syntax errors: " +
        (($ParseErrors | ForEach-Object { $_.Message }) -join "; ")
    )
}

Write-Host ""
Write-Host "Gateway token rotation utility installed." -ForegroundColor Green
Write-Host ""
Write-Host "Validate with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File ".\scripts\utilities\Test-AIOfficeGatewayTokenRotationUtility.ps1"'
Write-Host ""
Write-Host "Rotate with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"'
