param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part F Intelligence Operations and Live Validation..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    Get-Content ".\config\intelligence\operations-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\intelligence\operations-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid intelligence operations policy JSON.")
}

$Scripts = @(
    ".\scripts\intelligence\Get-AIOfficeIntelligenceOperationsStatus.ps1",
    ".\scripts\intelligence\Show-AIOfficeIntelligenceOperations.ps1",
    ".\scripts\intelligence\Invoke-AIOfficeLiveIntelligenceValidation.ps1",
    ".\scripts\intelligence\Test-AIOfficeIntelligenceOperations.ps1"
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
    $Validation = & ".\scripts\intelligence\Invoke-AIOfficeLiveIntelligenceValidation.ps1" -Persist

    if ([int]$Validation.failed -gt 0) {
        throw "$($Validation.failed) live intelligence validation case(s) failed."
    }

    Write-Host "[LIVE VALIDATION OK] $($Validation.passed)/$($Validation.passed + $Validation.failed) passed" -ForegroundColor Green

    foreach ($Result in @($Validation.results)) {
        Write-Host (
            "  - " + $Result.name +
            " -> " + $Result.model +
            " | family=" + $Result.task_family +
            " | fallback=" + $Result.fallback_used +
            " | escalation=" + $Result.requires_escalation
        ) -ForegroundColor DarkGray
    }
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[LIVE VALIDATION ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Ops = & ".\scripts\intelligence\Get-AIOfficeIntelligenceOperationsStatus.ps1"

    if ([int]$Ops.tracked_selections -lt 1) {
        throw "No intelligent model selections are being tracked."
    }

    Write-Host "[OPERATIONS OK] selections=$($Ops.tracked_selections) | intelligent turns=$($Ops.intelligent_turns) | fallbacks=$($Ops.fallback_turns)" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[OPERATIONS ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $DiscordOps = & "E:\AI\AI-Office\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1"

    if (
        -not [bool]$DiscordOps.discord_connected -or
        [string]$DiscordOps.worker_status -ne "running" -or
        [string]$DiscordOps.self_hosting_status -ne "healthy"
    ) {
        throw "Discord or self-hosting runtime is not healthy."
    }

    Write-Host "[DISCORD HEALTH OK] connected=True | worker=running | self-hosting=healthy" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[DISCORD HEALTH ERR] $($_.Exception.Message)" -ForegroundColor Red
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) Intelligence Operations and Live Validation error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part F Intelligence Operations and Live Validation checks passed." -ForegroundColor Green
