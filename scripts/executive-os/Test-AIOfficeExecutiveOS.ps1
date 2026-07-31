param()

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root.Path

Write-Host ""
Write-Host "Testing AI Office Executive Operating System v1.0..." `
    -ForegroundColor Cyan
Write-Host ""

$errors = New-Object System.Collections.Generic.List[string]

$jsonFiles = @(
    ".\config\executive-os\executive-os-policy.json",
    ".\workspace\executive-os\release-manifest.json",
    ".\workspace\executive-os\executive-os-index.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null
        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $file" -ForegroundColor Red
        $errors.Add("Invalid JSON: " + $file)
    }
}

$scripts = @(
    ".\scripts\executive-os\AIOfficeExecutiveOS.Common.ps1",
    ".\scripts\executive-os\Get-AIOfficeHealthReport.ps1",
    ".\scripts\executive-os\New-AIOfficeExecutiveBriefing.ps1",
    ".\scripts\executive-os\Start-AIOffice.ps1",
    ".\scripts\executive-os\Invoke-AIOfficeDailyRoutine.ps1",
    ".\scripts\executive-os\New-AIOfficeEndOfDayReport.ps1",
    ".\scripts\executive-os\New-AIOfficeWeeklyReport.ps1",
    ".\scripts\executive-os\New-AIOfficeMonthlyReport.ps1",
    ".\scripts\executive-os\Show-AIOfficeExecutiveStatus.ps1",
    ".\scripts\executive-os\Install-AIOfficeScheduledTasks.ps1",
    ".\scripts\executive-os\Publish-AIOfficeVersion1.ps1",
    ".\scripts\executive-os\Test-AIOfficeExecutiveOS.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $script" -ForegroundColor Red
        $errors.Add("Missing script: " + $script)
    }
}

$packageChecks = @(
    @{
        Name = "Package 12 dashboard"
        Path = ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1"
    },
    @{
        Name = "Package 13 automation"
        Path = ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1"
    },
    @{
        Name = "Package 14 collaboration"
        Path = ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1"
    }
)

foreach ($check in $packageChecks) {
    if (Test-Path -LiteralPath $check.Path -PathType Leaf) {
        Write-Host ("[INTEGRATION] " + $check.Name) -ForegroundColor Green
    }
    else {
        Write-Host ("[MISSING INT] " + $check.Name) -ForegroundColor Red
        $errors.Add("Missing integration: " + $check.Name)
    }
}

try {
    $health = & ".\scripts\executive-os\Get-AIOfficeHealthReport.ps1"

    if ($null -eq $health -or [int]$health.score -lt 1) {
        throw "Health report returned an invalid score."
    }

    Write-Host (
        "[HEALTH OK  ] " +
        [string]$health.score +
        "% " +
        [string]$health.status
    ) -ForegroundColor Green
}
catch {
    Write-Host "[HEALTH ERR ] Health report failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Health report failed: " + $_.Exception.Message)
}

try {
    $briefing = & ".\scripts\executive-os\New-AIOfficeExecutiveBriefing.ps1" `
        -Type "executive"

    if ([string]::IsNullOrWhiteSpace([string]$briefing.briefing_id)) {
        throw "Executive briefing did not contain an ID."
    }

    Write-Host (
        "[BRIEFING OK] " +
        [string]$briefing.briefing_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[BRIEFING ER] Executive briefing failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Executive briefing failed: " + $_.Exception.Message)
}

try {
    $startup = & ".\scripts\executive-os\Start-AIOffice.ps1" `
        -SkipAutomation `
        -SkipDashboard

    if ([string]::IsNullOrWhiteSpace([string]$startup.startup_id)) {
        throw "Startup routine did not contain an ID."
    }

    Write-Host (
        "[STARTUP OK ] " +
        [string]$startup.startup_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[STARTUP ERR] Startup routine failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Startup routine failed: " + $_.Exception.Message)
}

try {
    $release = & ".\scripts\executive-os\Publish-AIOfficeVersion1.ps1"

    if ([string]$release.version -ne "1.0.0") {
        throw "Release version did not equal 1.0.0."
    }

    Write-Host "[RELEASE OK ] AI Office v1.0" -ForegroundColor Green
}
catch {
    Write-Host "[RELEASE ERR] Release publication failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Release publication failed: " + $_.Exception.Message)
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $errors.Count.ToString() +
        " Executive OS error or errors were found."
    ) -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office Executive Operating System checks passed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "AI Office v1.0 is operational." -ForegroundColor Cyan
