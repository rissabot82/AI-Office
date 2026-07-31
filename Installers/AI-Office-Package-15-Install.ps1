# ============================================================
# AI Office Package 15
# Executive Operating System v1.0
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"
$repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $repository -PathType Container)) {
    throw "AI Office repository not found at $repository"
}

Set-Location $repository

function New-SafeDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function New-SafeFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $parent = Split-Path -Parent $Path

        if (-not [string]::IsNullOrWhiteSpace($parent) -and
            -not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

$folders = @(
    ".\config\executive-os",
    ".\workspace\executive-os",
    ".\workspace\executive-os\briefings",
    ".\workspace\executive-os\reports",
    ".\workspace\executive-os\health",
    ".\workspace\executive-os\releases",
    ".\workspace\executive-os\logs",
    ".\scripts\executive-os",
    ".\docs",
    ".\Installers"
)

foreach ($folder in $folders) {
    New-SafeDirectory -Path $folder
}

$policy = @'
{
  "version": "1.0.0",
  "system_name": "AI Office Executive Operating System",
  "default_timezone": "America/Chicago",
  "startup_components": [
    "automation",
    "collaboration",
    "dashboard",
    "workflows",
    "knowledge"
  ],
  "health_thresholds": {
    "healthy": 80,
    "warning": 60,
    "critical": 0
  },
  "report_retention_days": 365,
  "daily_briefing_hour": 7,
  "end_of_day_hour": 18,
  "weekly_report_day": "Friday",
  "monthly_report_day": 1,
  "release_name": "AI Office v1.0"
}
'@

New-SafeFile ".\config\executive-os\executive-os-policy.json" $policy

$manifest = @'
{
  "product": "AI Office",
  "version": "1.0.0",
  "release_name": "Executive Operating System",
  "release_status": "installed",
  "installed_at": "",
  "packages": [
    1, 2, 3, 4, 5,
    6, 7, 8, 9, 10,
    11, 12, 13, 14, 15
  ],
  "components": {
    "automation_engine": true,
    "agent_collaboration": true,
    "executive_dashboard": true,
    "executive_reporting": true,
    "health_monitoring": true,
    "startup_routine": true,
    "validation_suite": true
  }
}
'@

New-SafeFile ".\workspace\executive-os\release-manifest.json" $manifest

$index = @'
{
  "version": "1.0.0",
  "updated_at": "",
  "last_startup_at": "",
  "last_daily_briefing_at": "",
  "last_end_of_day_report_at": "",
  "last_weekly_report_at": "",
  "last_monthly_report_at": "",
  "office_health_score": 0,
  "office_health_status": "unknown",
  "latest_briefing": "",
  "latest_report": ""
}
'@

New-SafeFile ".\workspace\executive-os\executive-os-index.json" $index

$common = @'
$script:AIOfficeExecutiveOSRoot = $null

function Get-AIOfficeExecutiveOSRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeExecutiveOSRoot)) {
        return $script:AIOfficeExecutiveOSRoot
    }

    $resolved = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $script:AIOfficeExecutiveOSRoot = $resolved.Path
    return $script:AIOfficeExecutiveOSRoot
}

function Read-AIOfficeExecutiveOSJson {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Write-AIOfficeExecutiveOSJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $parent = Split-Path -Parent $Path

    if (-not [string]::IsNullOrWhiteSpace($parent) -and
        -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function ConvertTo-AIOfficeExecutiveOSArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function Get-AIOfficeFileCount {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Filter = "*.json"
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return 0
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Filter $Filter `
            -File `
            -ErrorAction SilentlyContinue
    ).Count
}

function Get-AIOfficeLatestFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Filter = "*"
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $null
    }

    return Get-ChildItem `
        -LiteralPath $Path `
        -Filter $Filter `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Update-AIOfficeExecutiveOSIndexField {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [AllowNull()]$Value
    )

    $root = Get-AIOfficeExecutiveOSRoot
    $path = Join-Path $root "workspace\executive-os\executive-os-index.json"
    $index = Read-AIOfficeExecutiveOSJson -Path $path

    if ($null -eq $index) {
        $index = [pscustomobject]@{
            version = "1.0.0"
            updated_at = ""
            last_startup_at = ""
            last_daily_briefing_at = ""
            last_end_of_day_report_at = ""
            last_weekly_report_at = ""
            last_monthly_report_at = ""
            office_health_score = 0
            office_health_status = "unknown"
            latest_briefing = ""
            latest_report = ""
        }
    }

    if ($null -ne $index.PSObject.Properties[$Name]) {
        $index.$Name = $Value
    }
    else {
        $index | Add-Member `
            -MemberType NoteProperty `
            -Name $Name `
            -Value $Value
    }

    $index.updated_at = (Get-Date).ToString("o")
    Write-AIOfficeExecutiveOSJson -Value $index -Path $path
}
'@

New-SafeFile ".\scripts\executive-os\AIOfficeExecutiveOS.Common.ps1" $common

$health = @'
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$checks = New-Object System.Collections.Generic.List[object]

function Add-HealthCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details,
        [int]$Weight = 10
    )

    $checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
        weight = $Weight
    })
}

Add-HealthCheck `
    -Name "Automation engine" `
    -Passed (Test-Path ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1") `
    -Details "Package 13 automation engine script" `
    -Weight 15

Add-HealthCheck `
    -Name "Collaboration layer" `
    -Passed (Test-Path ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1") `
    -Details "Package 14 collaboration script" `
    -Weight 15

Add-HealthCheck `
    -Name "Executive dashboard" `
    -Passed (Test-Path ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1") `
    -Details "Package 12 executive dashboard script" `
    -Weight 15

Add-HealthCheck `
    -Name "Automation index" `
    -Passed (Test-Path ".\workspace\automation\automation-index.json") `
    -Details "Automation index data" `
    -Weight 10

Add-HealthCheck `
    -Name "Collaboration index" `
    -Passed (Test-Path ".\workspace\collaboration\collaboration-index.json") `
    -Details "Collaboration index data" `
    -Weight 10

Add-HealthCheck `
    -Name "Executive OS index" `
    -Passed (Test-Path ".\workspace\executive-os\executive-os-index.json") `
    -Details "Executive OS index data" `
    -Weight 10

Add-HealthCheck `
    -Name "Knowledge workspace" `
    -Passed (Test-Path ".\workspace\knowledge") `
    -Details "Knowledge workspace" `
    -Weight 10

Add-HealthCheck `
    -Name "Workflow workspace" `
    -Passed (Test-Path ".\workspace\workflows") `
    -Details "Workflow workspace" `
    -Weight 10

Add-HealthCheck `
    -Name "Release manifest" `
    -Passed (Test-Path ".\workspace\executive-os\release-manifest.json") `
    -Details "Version 1.0 release manifest" `
    -Weight 5

$totalWeight = [int](($checks | Measure-Object -Property weight -Sum).Sum)
$passedWeight = [int]((
    $checks |
    Where-Object { $_.passed -eq $true } |
    Measure-Object -Property weight -Sum
).Sum)

$score = 0

if ($totalWeight -gt 0) {
    $score = [int][math]::Round(($passedWeight / $totalWeight) * 100)
}

$status = "critical"

if ($score -ge 80) {
    $status = "healthy"
}
elseif ($score -ge 60) {
    $status = "warning"
}

$record = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    score = $score
    status = $status
    passed_checks = @($checks | Where-Object { $_.passed -eq $true }).Count
    failed_checks = @($checks | Where-Object { $_.passed -eq $false }).Count
    checks = @($checks | ForEach-Object { $_ })
}

$fileName = "health-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json"
$path = Join-Path ".\workspace\executive-os\health" $fileName

Write-AIOfficeExecutiveOSJson -Value $record -Path $path
Update-AIOfficeExecutiveOSIndexField -Name "office_health_score" -Value $score
Update-AIOfficeExecutiveOSIndexField -Name "office_health_status" -Value $status

Write-Host (
    "Office health: " +
    $score.ToString() +
    "% (" +
    $status +
    ")"
) -ForegroundColor Green

return [pscustomobject]$record
'@

New-SafeFile ".\scripts\executive-os\Get-AIOfficeHealthReport.ps1" $health

$briefing = @'
param(
    [ValidateSet("daily","end_of_day","weekly","monthly","executive")]
    [string]$Type = "daily"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$health = & ".\scripts\executive-os\Get-AIOfficeHealthReport.ps1"

$automationIndex = Read-AIOfficeExecutiveOSJson `
    -Path ".\workspace\automation\automation-index.json"

$collaborationIndex = Read-AIOfficeExecutiveOSJson `
    -Path ".\workspace\collaboration\collaboration-index.json"

$workflowCount = Get-AIOfficeFileCount `
    -Path ".\workspace\workflows" `
    -Filter "*.json"

$knowledgeCount = Get-AIOfficeFileCount `
    -Path ".\workspace\knowledge" `
    -Filter "*.json"

$dashboardSnapshot = Get-AIOfficeLatestFile `
    -Path ".\workspace\dashboard" `
    -Filter "*.json"

$automationRuleCount = 0
$queuedEventCount = 0
$executionCount = 0

if ($null -ne $automationIndex) {
    $automationRuleCount = [int]$automationIndex.rule_count
    $queuedEventCount = [int]$automationIndex.queued_event_count
    $executionCount = [int]$automationIndex.execution_count
}

$agentCount = 0
$availableAgentCount = 0
$openDelegationCount = 0
$openConflictCount = 0

if ($null -ne $collaborationIndex) {
    $agentCount = [int]$collaborationIndex.agent_count
    $availableAgentCount = [int]$collaborationIndex.available_agent_count
    $openDelegationCount = [int]$collaborationIndex.open_delegation_count
    $openConflictCount = [int]$collaborationIndex.open_conflict_count
}

$record = [ordered]@{
    briefing_id = "BRF-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
    type = $Type
    generated_at = (Get-Date).ToString("o")
    executive_summary = [ordered]@{
        office_health_score = [int]$health.score
        office_health_status = [string]$health.status
        workflow_records = [int]$workflowCount
        knowledge_records = [int]$knowledgeCount
        automation_rules = [int]$automationRuleCount
        queued_automation_events = [int]$queuedEventCount
        automation_executions = [int]$executionCount
        agents = [int]$agentCount
        available_agents = [int]$availableAgentCount
        open_delegations = [int]$openDelegationCount
        open_conflicts = [int]$openConflictCount
    }
    priorities = @(
        "Review critical and warning health checks.",
        "Review overdue and high-priority workflows.",
        "Review open delegations and conflicts.",
        "Process queued automation events.",
        "Refresh executive dashboard snapshot."
    )
    latest_dashboard_snapshot = if ($null -ne $dashboardSnapshot) {
        $dashboardSnapshot.FullName
    }
    else {
        ""
    }
}

$folder = ".\workspace\executive-os\briefings"

if ($Type -in @("end_of_day","weekly","monthly")) {
    $folder = ".\workspace\executive-os\reports"
}

$fileName = $Type + "-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json"
$path = Join-Path $folder $fileName

Write-AIOfficeExecutiveOSJson -Value $record -Path $path

switch ($Type) {
    "daily" {
        Update-AIOfficeExecutiveOSIndexField `
            -Name "last_daily_briefing_at" `
            -Value $record.generated_at
        Update-AIOfficeExecutiveOSIndexField `
            -Name "latest_briefing" `
            -Value $path
    }
    "executive" {
        Update-AIOfficeExecutiveOSIndexField `
            -Name "latest_briefing" `
            -Value $path
    }
    "end_of_day" {
        Update-AIOfficeExecutiveOSIndexField `
            -Name "last_end_of_day_report_at" `
            -Value $record.generated_at
        Update-AIOfficeExecutiveOSIndexField `
            -Name "latest_report" `
            -Value $path
    }
    "weekly" {
        Update-AIOfficeExecutiveOSIndexField `
            -Name "last_weekly_report_at" `
            -Value $record.generated_at
        Update-AIOfficeExecutiveOSIndexField `
            -Name "latest_report" `
            -Value $path
    }
    "monthly" {
        Update-AIOfficeExecutiveOSIndexField `
            -Name "last_monthly_report_at" `
            -Value $record.generated_at
        Update-AIOfficeExecutiveOSIndexField `
            -Name "latest_report" `
            -Value $path
    }
}

Write-Host (
    $Type +
    " briefing generated: " +
    $path
) -ForegroundColor Green

return [pscustomobject]$record
'@

New-SafeFile ".\scripts\executive-os\New-AIOfficeExecutiveBriefing.ps1" $briefing

$startup = @'
param(
    [switch]$SkipAutomation,
    [switch]$SkipDashboard
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$started = Get-Date
$steps = New-Object System.Collections.Generic.List[object]

function Add-StartupStep {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details
    )

    $steps.Add([ordered]@{
        name = $Name
        status = $Status
        details = $Details
    })
}

try {
    if (-not $SkipAutomation -and
        (Test-Path ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1")) {
        & ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1" | Out-Null
        Add-StartupStep "Automation engine" "success" "Queue processed."
    }
    else {
        Add-StartupStep "Automation engine" "skipped" "Not available or skipped."
    }
}
catch {
    Add-StartupStep "Automation engine" "warning" $_.Exception.Message
}

try {
    if (Test-Path ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1") {
        & ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null
        Add-StartupStep "Collaboration index" "success" "Index refreshed."
    }
    else {
        Add-StartupStep "Collaboration index" "skipped" "Script not found."
    }
}
catch {
    Add-StartupStep "Collaboration index" "warning" $_.Exception.Message
}

try {
    if (-not $SkipDashboard -and
        (Test-Path ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1")) {
        & ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" | Out-Null
        Add-StartupStep "Executive dashboard" "success" "Snapshot generated."
    }
    else {
        Add-StartupStep "Executive dashboard" "skipped" "Not available or skipped."
    }
}
catch {
    Add-StartupStep "Executive dashboard" "warning" $_.Exception.Message
}

try {
    $health = & ".\scripts\executive-os\Get-AIOfficeHealthReport.ps1"
    Add-StartupStep `
        "Office health" `
        "success" `
        ($health.score.ToString() + "% " + [string]$health.status)
}
catch {
    Add-StartupStep "Office health" "warning" $_.Exception.Message
}

try {
    $briefing = & ".\scripts\executive-os\New-AIOfficeExecutiveBriefing.ps1" `
        -Type "daily"
    Add-StartupStep `
        "Daily briefing" `
        "success" `
        ([string]$briefing.briefing_id)
}
catch {
    Add-StartupStep "Daily briefing" "warning" $_.Exception.Message
}

$completed = Get-Date
$record = [ordered]@{
    startup_id = "START-" + $started.ToString("yyyyMMdd-HHmmss")
    started_at = $started.ToString("o")
    completed_at = $completed.ToString("o")
    duration_seconds = [math]::Round(($completed - $started).TotalSeconds, 2)
    steps = @($steps | ForEach-Object { $_ })
}

$path = Join-Path `
    ".\workspace\executive-os\logs" `
    ("startup-" + $started.ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeExecutiveOSJson -Value $record -Path $path
Update-AIOfficeExecutiveOSIndexField `
    -Name "last_startup_at" `
    -Value $record.completed_at

Write-Host ""
Write-Host "AI Office startup routine completed." -ForegroundColor Green
Write-Host ""

return [pscustomobject]$record
'@

New-SafeFile ".\scripts\executive-os\Start-AIOffice.ps1" $startup

$daily = @'
param()

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "Start-AIOffice.ps1")
'@

New-SafeFile ".\scripts\executive-os\Invoke-AIOfficeDailyRoutine.ps1" $daily

$eod = @'
param()

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "New-AIOfficeExecutiveBriefing.ps1") `
    -Type "end_of_day"
'@

New-SafeFile ".\scripts\executive-os\New-AIOfficeEndOfDayReport.ps1" $eod

$weekly = @'
param()

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "New-AIOfficeExecutiveBriefing.ps1") `
    -Type "weekly"
'@

New-SafeFile ".\scripts\executive-os\New-AIOfficeWeeklyReport.ps1" $weekly

$monthly = @'
param()

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "New-AIOfficeExecutiveBriefing.ps1") `
    -Type "monthly"
'@

New-SafeFile ".\scripts\executive-os\New-AIOfficeMonthlyReport.ps1" $monthly

$status = @'
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$index = Read-AIOfficeExecutiveOSJson `
    -Path ".\workspace\executive-os\executive-os-index.json"

$automation = Read-AIOfficeExecutiveOSJson `
    -Path ".\workspace\automation\automation-index.json"

$collaboration = Read-AIOfficeExecutiveOSJson `
    -Path ".\workspace\collaboration\collaboration-index.json"

Write-Host ""
Write-Host "AI OFFICE EXECUTIVE OPERATING SYSTEM v1.0" -ForegroundColor Cyan
Write-Host ("=" * 72)

if ($null -ne $index) {
    Write-Host (
        "Health: " +
        [string]$index.office_health_score +
        "% (" +
        [string]$index.office_health_status +
        ")"
    )
    Write-Host ("Last startup: " + [string]$index.last_startup_at)
    Write-Host ("Latest briefing: " + [string]$index.latest_briefing)
    Write-Host ("Latest report: " + [string]$index.latest_report)
}

if ($null -ne $automation) {
    Write-Host ""
    Write-Host (
        "Automation: " +
        [string]$automation.rule_count +
        " rule(s), " +
        [string]$automation.queued_event_count +
        " queued event(s)"
    )
}

if ($null -ne $collaboration) {
    Write-Host (
        "Agents: " +
        [string]$collaboration.agent_count +
        " total, " +
        [string]$collaboration.available_agent_count +
        " available"
    )
    Write-Host (
        "Delegations: " +
        [string]$collaboration.open_delegation_count +
        " open"
    )
    Write-Host (
        "Conflicts: " +
        [string]$collaboration.open_conflict_count +
        " open"
    )
}

Write-Host ""
return $index
'@

New-SafeFile ".\scripts\executive-os\Show-AIOfficeExecutiveStatus.ps1" $status

$schedule = @'
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$dailyScript = Join-Path $root.Path "scripts\executive-os\Invoke-AIOfficeDailyRoutine.ps1"
$eodScript = Join-Path $root.Path "scripts\executive-os\New-AIOfficeEndOfDayReport.ps1"
$weeklyScript = Join-Path $root.Path "scripts\executive-os\New-AIOfficeWeeklyReport.ps1"
$monthlyScript = Join-Path $root.Path "scripts\executive-os\New-AIOfficeMonthlyReport.ps1"

$tasks = @(
    @{
        Name = "AI Office Daily Startup"
        Time = "07:00"
        Schedule = "DAILY"
        Script = $dailyScript
    },
    @{
        Name = "AI Office End of Day"
        Time = "18:00"
        Schedule = "DAILY"
        Script = $eodScript
    }
)

foreach ($task in $tasks) {
    $arguments = @(
        "/Create",
        "/TN", $task.Name,
        "/SC", $task.Schedule,
        "/ST", $task.Time,
        "/TR",
        ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $task.Script + '"')
    )

    if ($Force) {
        $arguments += "/F"
    }

    & schtasks.exe @arguments | Out-Null
    Write-Host ("Scheduled task created: " + $task.Name) -ForegroundColor Green
}

Write-Host ""
Write-Host "Weekly and monthly reports can be scheduled manually if desired." `
    -ForegroundColor Yellow
Write-Host ("Weekly script: " + $weeklyScript)
Write-Host ("Monthly script: " + $monthlyScript)
'@

New-SafeFile ".\scripts\executive-os\Install-AIOfficeScheduledTasks.ps1" $schedule

$release = @'
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$manifestPath = ".\workspace\executive-os\release-manifest.json"
$manifest = Read-AIOfficeExecutiveOSJson -Path $manifestPath

if ($null -eq $manifest) {
    throw "Release manifest could not be loaded."
}

$now = (Get-Date).ToString("o")
$manifest.installed_at = $now
$manifest.release_status = "released"

Write-AIOfficeExecutiveOSJson -Value $manifest -Path $manifestPath

$releaseRecord = [ordered]@{
    product = "AI Office"
    version = "1.0.0"
    release_name = "Executive Operating System"
    released_at = $now
    status = "released"
    validation_required = true
}

$path = Join-Path `
    ".\workspace\executive-os\releases" `
    ("AI-Office-v1.0-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeExecutiveOSJson -Value $releaseRecord -Path $path

Write-Host "AI Office v1.0 release recorded." -ForegroundColor Green
return [pscustomobject]$releaseRecord
'@

New-SafeFile ".\scripts\executive-os\Publish-AIOfficeVersion1.ps1" $release

$validate = @'
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
'@

New-SafeFile ".\scripts\executive-os\Test-AIOfficeExecutiveOS.ps1" $validate

$guide = @'
# AI Office Package 15 — Executive Operating System v1.0

Package 15 completes the first full release of AI Office.

## Included capabilities

- Startup routine
- Daily briefing
- Executive summary
- Office health report
- End-of-day report
- Weekly report
- Monthly report
- Agent status
- Workflow status
- Knowledge metrics
- Automation status
- Collaboration status
- Dashboard integration
- Scheduled-task installer
- Release manifest
- Full validation suite

## Start AI Office

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\Start-AIOffice.ps1"
```

## Show executive status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\Show-AIOfficeExecutiveStatus.ps1"
```

## Generate reports

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\New-AIOfficeEndOfDayReport.ps1"
```

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\New-AIOfficeWeeklyReport.ps1"
```

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\New-AIOfficeMonthlyReport.ps1"
```

## Install Windows scheduled tasks

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\Install-AIOfficeScheduledTasks.ps1" `
    -Force
```

This creates:

- AI Office Daily Startup at 7:00 AM
- AI Office End of Day at 6:00 PM

## Validate version 1.0

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\Test-AIOfficeExecutiveOS.ps1"
```

Expected result:

```text
All AI Office Executive Operating System checks passed.
AI Office v1.0 is operational.
```

## Release status

Package 15 completes:

- Packages 1 through 15
- Automation Engine
- Agent Collaboration Layer
- Executive Dashboard
- Executive Reporting
- Office Health Monitoring
- Executive Operating System v1.0
'@

New-SafeFile ".\docs\AI-Office-v1.0-Guide.md" $guide

$readme = @'
# AI Office v1.0

AI Office is a local executive operating system for coordinating work, knowledge, workflows, automation, agents, reporting, and personal projects.

## Primary command

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\Start-AIOffice.ps1"
```

## Status command

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\Show-AIOfficeExecutiveStatus.ps1"
```

## Validation command

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\executive-os\Test-AIOfficeExecutiveOS.ps1"
```
'@

New-SafeFile ".\README-AI-OFFICE-V1.md" $readme

Write-Host ""
Write-Host "Validating Package 15 JSON files..." -ForegroundColor Cyan

$validationFiles = @(
    ".\config\executive-os\executive-os-policy.json",
    ".\workspace\executive-os\release-manifest.json",
    ".\workspace\executive-os\executive-os-index.json"
)

foreach ($file in $validationFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null
        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        throw (
            "Package 15 JSON validation failed for " +
            $file +
            ": " +
            $_.Exception.Message
        )
    }
}

try {
    $source = $MyInvocation.MyCommand.Path

    if (-not [string]::IsNullOrWhiteSpace($source) -and
        (Test-Path -LiteralPath $source -PathType Leaf)) {
        $destination = Join-Path `
            $repository `
            "Installers\AI-Office-Package-15-Install.ps1"

        if ([System.IO.Path]::GetFullPath($source) -ne
            [System.IO.Path]::GetFullPath($destination)) {
            Copy-Item `
                -LiteralPath $source `
                -Destination $destination `
                -Force

            Write-Host (
                "[COPIED ] Installer saved to " +
                $destination
            ) -ForegroundColor Green
        }
        else {
            Write-Host "[EXISTS ] Installer is already in the Installers folder." `
                -ForegroundColor DarkGray
        }
    }
}
catch {
    Write-Host (
        "[WARNING] Installer copy was not completed: " +
        $_.Exception.Message
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "AI Office Package 15 installation completed." -ForegroundColor Green
Write-Host ""
Write-Host "Run final validation with:" -ForegroundColor Cyan
Write-Host ""
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\executive-os\Test-AIOfficeExecutiveOS.ps1"'
Write-Host ""
