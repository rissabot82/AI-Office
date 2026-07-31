# ============================================================
# AI Office Package 12
# Executive Dashboard and Operational Intelligence
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"

$expectedRepository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $expectedRepository -PathType Container)) {
    throw "AI Office repository not found at $expectedRepository"
}

Set-Location $expectedRepository

function New-SafeDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

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
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $parent = Split-Path -Parent $Path

        if (
            -not [string]::IsNullOrWhiteSpace($parent) -and
            -not (Test-Path -LiteralPath $parent -PathType Container)
        ) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

$requiredFolders = @(
    ".\config\dashboard",
    ".\workspace\dashboard",
    ".\workspace\dashboard\snapshots",
    ".\workspace\dashboard\reports",
    ".\workspace\dashboard\exports",
    ".\workspace\dashboard\archive",
    ".\scripts\dashboard",
    ".\docs",
    ".\Installers"
)

foreach ($folder in $requiredFolders) {
    New-SafeDirectory -Path $folder
}

$dashboardPolicy = @'
{
  "version": "1.0.0",
  "dashboard_name": "AI Office Executive Dashboard",
  "default_timezone": "America/Chicago",
  "snapshot_retention_days": 90,
  "stale_snapshot_hours": 24,
  "health_thresholds": {
    "healthy_minimum": 80,
    "attention_minimum": 55,
    "critical_below": 55
  },
  "risk_weights": {
    "overdue_work": 25,
    "blocked_work": 25,
    "pending_approvals": 15,
    "overdue_calendar": 15,
    "stale_knowledge": 10,
    "system_validation": 10
  },
  "supported_sections": [
    "executive_summary",
    "workflows",
    "approvals",
    "calendar",
    "knowledge",
    "system_health",
    "risks",
    "recommendations"
  ],
  "html_report": {
    "enabled": true,
    "open_after_generation": false
  },
  "severity_order": [
    "critical",
    "high",
    "medium",
    "low",
    "informational"
  ]
}
'@

New-SafeFile ".\config\dashboard\dashboard-policy.json" $dashboardPolicy

$dashboardSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/executive-dashboard-schema.json",
  "title": "AI Office Executive Dashboard Snapshot",
  "type": "object",
  "required": [
    "snapshot_id",
    "generated_at",
    "repository",
    "overall_health",
    "executive_summary",
    "metrics",
    "risks",
    "recommendations",
    "sources"
  ],
  "properties": {
    "snapshot_id": {
      "type": "string",
      "pattern": "^DSH-[0-9]{8}-[0-9]{6}$"
    },
    "generated_at": {
      "type": "string"
    },
    "repository": {
      "type": "string"
    },
    "overall_health": {
      "type": "object",
      "required": [
        "score",
        "status",
        "risk_count"
      ],
      "properties": {
        "score": {
          "type": "integer",
          "minimum": 0,
          "maximum": 100
        },
        "status": {
          "type": "string",
          "enum": [
            "healthy",
            "attention",
            "critical"
          ]
        },
        "risk_count": {
          "type": "integer",
          "minimum": 0
        }
      }
    },
    "executive_summary": {
      "type": "string"
    },
    "metrics": {
      "type": "object"
    },
    "risks": {
      "type": "array"
    },
    "recommendations": {
      "type": "array"
    },
    "sources": {
      "type": "array"
    }
  }
}
'@

New-SafeFile ".\config\dashboard\executive-dashboard-schema.json" $dashboardSchema

$dashboardIndex = @'
{
  "version": "1.0.0",
  "updated_at": "",
  "latest_snapshot": "",
  "snapshot_count": 0,
  "snapshots": []
}
'@

New-SafeFile ".\workspace\dashboard\dashboard-index.json" $dashboardIndex

$dashboardTemplate = @'
{
  "snapshot_id": "",
  "generated_at": "",
  "repository": "E:\\AI\\AI-Office",
  "overall_health": {
    "score": 100,
    "status": "healthy",
    "risk_count": 0
  },
  "executive_summary": "",
  "metrics": {
    "workflows": {
      "total": 0,
      "active": 0,
      "completed": 0,
      "blocked": 0,
      "overdue": 0
    },
    "approvals": {
      "total": 0,
      "pending": 0,
      "approved": 0,
      "rejected": 0
    },
    "calendar": {
      "total": 0,
      "today": 0,
      "next_7_days": 0,
      "overdue": 0
    },
    "knowledge": {
      "total": 0,
      "active": 0,
      "archived": 0,
      "stale": 0
    },
    "system": {
      "json_files_checked": 0,
      "invalid_json_files": 0,
      "required_components_found": 0,
      "required_components_missing": 0
    }
  },
  "risks": [],
  "recommendations": [],
  "sources": []
}
'@

New-SafeFile ".\workspace\templates\executive-dashboard-template.json" $dashboardTemplate

$commonScript = @'
$script:AIOfficeDashboardRoot = $null

function Get-AIOfficeDashboardRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeDashboardRoot)) {
        return $script:AIOfficeDashboardRoot
    }

    $candidate = Resolve-Path (
        Join-Path $PSScriptRoot "..\.."
    )

    $script:AIOfficeDashboardRoot = $candidate.Path
    return $script:AIOfficeDashboardRoot
}

function ConvertTo-AIOfficeDashboardArray {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return @()
    }

    return @($Value)
}

function Get-AIOfficePropertyValue {
    param(
        [AllowNull()]
        $Object,

        [Parameter(Mandatory = $true)]
        [string[]]$Names,

        [AllowNull()]
        $Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties[$name]

        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $Default
}

function ConvertTo-AIOfficeDashboardDate {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $text = [string]$Value

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    $parsed = [datetime]::MinValue

    if ([datetime]::TryParse($text, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Read-AIOfficeJsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

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

function Get-AIOfficeJsonFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Filter "*.json" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue
    )
}

function Get-AIOfficeDashboardStatus {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Score,

        [Parameter(Mandatory = $true)]
        $Policy
    )

    $healthyMinimum = [int]$Policy.health_thresholds.healthy_minimum
    $attentionMinimum = [int]$Policy.health_thresholds.attention_minimum

    if ($Score -ge $healthyMinimum) {
        return "healthy"
    }

    if ($Score -ge $attentionMinimum) {
        return "attention"
    }

    return "critical"
}

function New-AIOfficeDashboardRisk {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RiskId,

        [Parameter(Mandatory = $true)]
        [string]$Severity,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Detail,

        [Parameter(Mandatory = $true)]
        [string]$RecommendedAction
    )

    return [ordered]@{
        risk_id = $RiskId
        severity = $Severity
        category = $Category
        title = $Title
        detail = $Detail
        recommended_action = $RecommendedAction
    }
}

function ConvertTo-AIOfficeHtmlText {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}
'@

New-SafeFile ".\scripts\dashboard\AIOfficeDashboard.Common.ps1" $commonScript

$snapshotScript = @'
param(
    [switch]$NoIndexUpdate,
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

$policy = Read-AIOfficeJsonFile `
    -Path ".\config\dashboard\dashboard-policy.json"

if ($null -eq $policy) {
    throw "Dashboard policy could not be loaded."
}

$now = Get-Date
$today = $now.Date
$nextSevenDays = $today.AddDays(7)
$staleCutoff = $now.AddDays(-30)

$sources = New-Object System.Collections.Generic.List[object]
$risks = New-Object System.Collections.Generic.List[object]
$recommendations = New-Object System.Collections.Generic.List[string]

$workflowMetrics = [ordered]@{
    total = 0
    active = 0
    completed = 0
    blocked = 0
    overdue = 0
}

$approvalMetrics = [ordered]@{
    total = 0
    pending = 0
    approved = 0
    rejected = 0
}

$calendarMetrics = [ordered]@{
    total = 0
    today = 0
    next_7_days = 0
    overdue = 0
}

$knowledgeMetrics = [ordered]@{
    total = 0
    active = 0
    archived = 0
    stale = 0
}

$systemMetrics = [ordered]@{
    json_files_checked = 0
    invalid_json_files = 0
    required_components_found = 0
    required_components_missing = 0
}

# ------------------------------------------------------------
# Workflow metrics
# ------------------------------------------------------------

$workflowCandidates = @(
    ".\workspace\workflows\workflow-index.json",
    ".\workspace\workflow\workflow-index.json",
    ".\workspace\workflows\index.json"
)

$workflowIndexPath = $workflowCandidates |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1

$workflowItems = @()

if (-not [string]::IsNullOrWhiteSpace($workflowIndexPath)) {
    $workflowIndex = Read-AIOfficeJsonFile -Path $workflowIndexPath

    if ($null -ne $workflowIndex) {
        $workflowItems = ConvertTo-AIOfficeDashboardArray (
            Get-AIOfficePropertyValue `
                -Object $workflowIndex `
                -Names @("workflows", "items", "records") `
                -Default @()
        )

        $sources.Add([ordered]@{
            section = "workflows"
            path = $workflowIndexPath
            available = $true
        })
    }
}
else {
    $workflowFiles = Get-AIOfficeJsonFiles -Path ".\workspace\workflows"
    $workflowItems = @(
        $workflowFiles |
        ForEach-Object { Read-AIOfficeJsonFile -Path $_.FullName } |
        Where-Object { $null -ne $_ }
    )

    $sources.Add([ordered]@{
        section = "workflows"
        path = ".\workspace\workflows"
        available = (Test-Path -LiteralPath ".\workspace\workflows")
    })
}

foreach ($workflow in $workflowItems) {
    $workflowMetrics.total++

    $status = [string](
        Get-AIOfficePropertyValue `
            -Object $workflow `
            -Names @("status", "state") `
            -Default "unknown"
    )

    $status = $status.ToLowerInvariant()

    if ($status -in @("active", "in-progress", "running", "queued", "open")) {
        $workflowMetrics.active++
    }

    if ($status -in @("completed", "complete", "done", "closed")) {
        $workflowMetrics.completed++
    }

    if ($status -in @("blocked", "failed", "error", "waiting")) {
        $workflowMetrics.blocked++
    }

    $dueValue = Get-AIOfficePropertyValue `
        -Object $workflow `
        -Names @("due_at", "due_date", "deadline", "target_date")

    $dueDate = ConvertTo-AIOfficeDashboardDate -Value $dueValue

    if (
        $null -ne $dueDate -and
        $dueDate -lt $now -and
        $status -notin @("completed", "complete", "done", "closed", "cancelled", "archived")
    ) {
        $workflowMetrics.overdue++
    }
}

# ------------------------------------------------------------
# Approval metrics
# ------------------------------------------------------------

$approvalCandidates = @(
    ".\workspace\approvals\approval-index.json",
    ".\workspace\approvals\approvals-index.json",
    ".\workspace\approvals\index.json"
)

$approvalIndexPath = $approvalCandidates |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1

$approvalItems = @()

if (-not [string]::IsNullOrWhiteSpace($approvalIndexPath)) {
    $approvalIndex = Read-AIOfficeJsonFile -Path $approvalIndexPath

    if ($null -ne $approvalIndex) {
        $approvalItems = ConvertTo-AIOfficeDashboardArray (
            Get-AIOfficePropertyValue `
                -Object $approvalIndex `
                -Names @("approvals", "items", "records") `
                -Default @()
        )

        $sources.Add([ordered]@{
            section = "approvals"
            path = $approvalIndexPath
            available = $true
        })
    }
}
else {
    $approvalFiles = Get-AIOfficeJsonFiles -Path ".\workspace\approvals"
    $approvalItems = @(
        $approvalFiles |
        ForEach-Object { Read-AIOfficeJsonFile -Path $_.FullName } |
        Where-Object { $null -ne $_ }
    )

    $sources.Add([ordered]@{
        section = "approvals"
        path = ".\workspace\approvals"
        available = (Test-Path -LiteralPath ".\workspace\approvals")
    })
}

foreach ($approval in $approvalItems) {
    $approvalMetrics.total++

    $status = [string](
        Get-AIOfficePropertyValue `
            -Object $approval `
            -Names @("status", "decision", "state") `
            -Default "pending"
    )

    $status = $status.ToLowerInvariant()

    if ($status -in @("pending", "requested", "waiting", "open")) {
        $approvalMetrics.pending++
    }

    if ($status -in @("approved", "accepted")) {
        $approvalMetrics.approved++
    }

    if ($status -in @("rejected", "denied", "declined")) {
        $approvalMetrics.rejected++
    }
}

# ------------------------------------------------------------
# Calendar metrics
# ------------------------------------------------------------

$calendarIndexPath = ".\workspace\calendar\calendar-index.json"
$calendarItems = @()

if (Test-Path -LiteralPath $calendarIndexPath -PathType Leaf) {
    $calendarIndex = Read-AIOfficeJsonFile -Path $calendarIndexPath

    if ($null -ne $calendarIndex) {
        $calendarItems = ConvertTo-AIOfficeDashboardArray (
            Get-AIOfficePropertyValue `
                -Object $calendarIndex `
                -Names @("events", "items") `
                -Default @()
        )
    }

    $sources.Add([ordered]@{
        section = "calendar"
        path = $calendarIndexPath
        available = $true
    })
}
else {
    $sources.Add([ordered]@{
        section = "calendar"
        path = $calendarIndexPath
        available = $false
    })
}

foreach ($event in $calendarItems) {
    $calendarMetrics.total++

    $status = [string](
        Get-AIOfficePropertyValue `
            -Object $event `
            -Names @("status", "state") `
            -Default "scheduled"
    )

    $status = $status.ToLowerInvariant()

    $startValue = Get-AIOfficePropertyValue `
        -Object $event `
        -Names @("start_at", "start", "scheduled_at", "due_at")

    $startDate = ConvertTo-AIOfficeDashboardDate -Value $startValue

    if ($null -ne $startDate) {
        if ($startDate.Date -eq $today) {
            $calendarMetrics.today++
        }

        if ($startDate -ge $today -and $startDate -lt $nextSevenDays) {
            $calendarMetrics.next_7_days++
        }

        if (
            $startDate -lt $now -and
            $status -notin @("completed", "cancelled", "archived")
        ) {
            $calendarMetrics.overdue++
        }
    }
}

# ------------------------------------------------------------
# Knowledge metrics
# ------------------------------------------------------------

$knowledgeIndexPath = ".\workspace\knowledge\knowledge-index.json"
$knowledgeItems = @()

if (Test-Path -LiteralPath $knowledgeIndexPath -PathType Leaf) {
    $knowledgeIndex = Read-AIOfficeJsonFile -Path $knowledgeIndexPath

    if ($null -ne $knowledgeIndex) {
        $knowledgeItems = ConvertTo-AIOfficeDashboardArray (
            Get-AIOfficePropertyValue `
                -Object $knowledgeIndex `
                -Names @("entries", "knowledge", "items", "records") `
                -Default @()
        )
    }

    $sources.Add([ordered]@{
        section = "knowledge"
        path = $knowledgeIndexPath
        available = $true
    })
}
else {
    $sources.Add([ordered]@{
        section = "knowledge"
        path = $knowledgeIndexPath
        available = $false
    })
}

foreach ($entry in $knowledgeItems) {
    $knowledgeMetrics.total++

    $status = [string](
        Get-AIOfficePropertyValue `
            -Object $entry `
            -Names @("status", "state") `
            -Default "active"
    )

    $status = $status.ToLowerInvariant()

    if ($status -in @("archived", "retired", "deleted")) {
        $knowledgeMetrics.archived++
    }
    else {
        $knowledgeMetrics.active++
    }

    $updatedValue = Get-AIOfficePropertyValue `
        -Object $entry `
        -Names @("updated_at", "modified_at", "reviewed_at", "created_at")

    $updatedDate = ConvertTo-AIOfficeDashboardDate -Value $updatedValue

    if (
        $null -ne $updatedDate -and
        $updatedDate -lt $staleCutoff -and
        $status -notin @("archived", "retired", "deleted")
    ) {
        $knowledgeMetrics.stale++
    }
}

# ------------------------------------------------------------
# System-health metrics
# ------------------------------------------------------------

$jsonFiles = @(
    Get-ChildItem `
        -LiteralPath ".\config" `
        -Filter "*.json" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue

    Get-ChildItem `
        -LiteralPath ".\workspace" `
        -Filter "*.json" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue
)

foreach ($file in $jsonFiles) {
    $systemMetrics.json_files_checked++

    try {
        Get-Content -LiteralPath $file.FullName -Raw |
            ConvertFrom-Json |
            Out-Null
    }
    catch {
        $systemMetrics.invalid_json_files++
    }
}

$requiredComponents = @(
    ".\config\dashboard\dashboard-policy.json",
    ".\config\dashboard\executive-dashboard-schema.json",
    ".\workspace\dashboard\dashboard-index.json",
    ".\scripts\dashboard\AIOfficeDashboard.Common.ps1",
    ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1",
    ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1",
    ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1",
    ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1",
    ".\scripts\dashboard\Test-AIOfficeExecutiveDashboard.ps1"
)

foreach ($component in $requiredComponents) {
    if (Test-Path -LiteralPath $component) {
        $systemMetrics.required_components_found++
    }
    else {
        $systemMetrics.required_components_missing++
    }
}

# ------------------------------------------------------------
# Risks and recommendations
# ------------------------------------------------------------

if ($workflowMetrics.overdue -gt 0) {
    $risks.Add(
        (New-AIOfficeDashboardRisk `
            -RiskId "RISK-WORKFLOW-OVERDUE" `
            -Severity "high" `
            -Category "workflows" `
            -Title "Overdue workflows require attention" `
            -Detail ($workflowMetrics.overdue.ToString() + " workflow(s) are overdue.") `
            -RecommendedAction "Review overdue workflows and assign owners or revised deadlines.")
    )

    $recommendations.Add(
        "Review and resolve overdue workflows."
    )
}

if ($workflowMetrics.blocked -gt 0) {
    $risks.Add(
        (New-AIOfficeDashboardRisk `
            -RiskId "RISK-WORKFLOW-BLOCKED" `
            -Severity "high" `
            -Category "workflows" `
            -Title "Blocked workflows may delay operations" `
            -Detail ($workflowMetrics.blocked.ToString() + " workflow(s) are blocked.") `
            -RecommendedAction "Identify the dependency blocking each workflow and escalate where needed.")
    )

    $recommendations.Add(
        "Clear blocked workflow dependencies."
    )
}

if ($approvalMetrics.pending -gt 0) {
    $risks.Add(
        (New-AIOfficeDashboardRisk `
            -RiskId "RISK-APPROVAL-PENDING" `
            -Severity "medium" `
            -Category "approvals" `
            -Title "Pending approvals may delay execution" `
            -Detail ($approvalMetrics.pending.ToString() + " approval request(s) are pending.") `
            -RecommendedAction "Review pending approvals and record decisions.")
    )

    $recommendations.Add(
        "Process pending approval requests."
    )
}

if ($calendarMetrics.overdue -gt 0) {
    $risks.Add(
        (New-AIOfficeDashboardRisk `
            -RiskId "RISK-CALENDAR-OVERDUE" `
            -Severity "medium" `
            -Category "calendar" `
            -Title "Past-due calendar commitments remain open" `
            -Detail ($calendarMetrics.overdue.ToString() + " calendar event(s) are overdue.") `
            -RecommendedAction "Complete, reschedule, or cancel past-due events.")
    )

    $recommendations.Add(
        "Resolve overdue calendar commitments."
    )
}

if ($knowledgeMetrics.stale -gt 0) {
    $risks.Add(
        (New-AIOfficeDashboardRisk `
            -RiskId "RISK-KNOWLEDGE-STALE" `
            -Severity "low" `
            -Category "knowledge" `
            -Title "Knowledge records may need review" `
            -Detail ($knowledgeMetrics.stale.ToString() + " active knowledge record(s) have not been updated in 30 days.") `
            -RecommendedAction "Review stale knowledge records and confirm accuracy.")
    )

    $recommendations.Add(
        "Review stale knowledge records."
    )
}

if ($systemMetrics.invalid_json_files -gt 0) {
    $risks.Add(
        (New-AIOfficeDashboardRisk `
            -RiskId "RISK-SYSTEM-JSON" `
            -Severity "critical" `
            -Category "system_health" `
            -Title "Invalid JSON files were detected" `
            -Detail ($systemMetrics.invalid_json_files.ToString() + " JSON file(s) failed parsing.") `
            -RecommendedAction "Repair invalid JSON before relying on automated reporting.")
    )

    $recommendations.Add(
        "Repair invalid JSON files immediately."
    )
}

if ($systemMetrics.required_components_missing -gt 0) {
    $risks.Add(
        (New-AIOfficeDashboardRisk `
            -RiskId "RISK-SYSTEM-COMPONENTS" `
            -Severity "critical" `
            -Category "system_health" `
            -Title "Required dashboard components are missing" `
            -Detail ($systemMetrics.required_components_missing.ToString() + " required component(s) were not found.") `
            -RecommendedAction "Restore the missing dashboard files and rerun validation.")
    )

    $recommendations.Add(
        "Restore missing dashboard components."
    )
}

$riskScore = 0

if ($workflowMetrics.overdue -gt 0) {
    $riskScore += [int]$policy.risk_weights.overdue_work
}

if ($workflowMetrics.blocked -gt 0) {
    $riskScore += [int]$policy.risk_weights.blocked_work
}

if ($approvalMetrics.pending -gt 0) {
    $riskScore += [int]$policy.risk_weights.pending_approvals
}

if ($calendarMetrics.overdue -gt 0) {
    $riskScore += [int]$policy.risk_weights.overdue_calendar
}

if ($knowledgeMetrics.stale -gt 0) {
    $riskScore += [int]$policy.risk_weights.stale_knowledge
}

if (
    $systemMetrics.invalid_json_files -gt 0 -or
    $systemMetrics.required_components_missing -gt 0
) {
    $riskScore += [int]$policy.risk_weights.system_validation
}

$riskScore = [math]::Min(100, $riskScore)
$healthScore = [math]::Max(0, 100 - $riskScore)

$healthStatus = Get-AIOfficeDashboardStatus `
    -Score $healthScore `
    -Policy $policy

$summaryParts = New-Object System.Collections.Generic.List[string]
$summaryParts.Add(
    "Operational health is " +
    $healthStatus +
    " with a score of " +
    $healthScore.ToString() +
    " out of 100."
)

$summaryParts.Add(
    $workflowMetrics.active.ToString() +
    " active workflow(s), " +
    $approvalMetrics.pending.ToString() +
    " pending approval(s), and " +
    $calendarMetrics.next_7_days.ToString() +
    " calendar event(s) are scheduled in the next seven days."
)

if ($risks.Count -eq 0) {
    $summaryParts.Add(
        "No material operational risks were detected."
    )
}
else {
    $summaryParts.Add(
        $risks.Count.ToString() +
        " operational risk(s) require review."
    )
}

$snapshotId = "DSH-" + $now.ToString("yyyyMMdd-HHmmss")

$snapshot = [ordered]@{
    snapshot_id = $snapshotId
    generated_at = $now.ToString("o")
    repository = $root
    overall_health = [ordered]@{
        score = [int]$healthScore
        status = $healthStatus
        risk_count = [int]$risks.Count
    }
    executive_summary = ($summaryParts -join " ")
    metrics = [ordered]@{
        workflows = $workflowMetrics
        approvals = $approvalMetrics
        calendar = $calendarMetrics
        knowledge = $knowledgeMetrics
        system = $systemMetrics
    }
    risks = @($risks)
    recommendations = @($recommendations | Select-Object -Unique)
    sources = @($sources)
}

$snapshotPath = Join-Path `
    ".\workspace\dashboard\snapshots" `
    ($snapshotId + ".json")

$snapshot |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $snapshotPath -Encoding UTF8

if (-not $NoIndexUpdate) {
    & ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" |
        Out-Null
}

Write-Host "Executive dashboard snapshot created: $snapshotPath" `
    -ForegroundColor Green

if ($PassThru) {
    return [pscustomobject]$snapshot
}
'@

New-SafeFile ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" $snapshotScript

$indexScript = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

$snapshotFolder = ".\workspace\dashboard\snapshots"
$indexPath = ".\workspace\dashboard\dashboard-index.json"

$snapshots = @(
    Get-ChildItem `
        -LiteralPath $snapshotFolder `
        -Filter "DSH-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object {
        $snapshot = Read-AIOfficeJsonFile -Path $_.FullName

        if ($null -ne $snapshot) {
            [ordered]@{
                snapshot_id = [string]$snapshot.snapshot_id
                generated_at = [string]$snapshot.generated_at
                health_score = [int]$snapshot.overall_health.score
                health_status = [string]$snapshot.overall_health.status
                risk_count = [int]$snapshot.overall_health.risk_count
                file = $_.Name
            }
        }
    }
)

$latestSnapshot = ""

if ($snapshots.Count -gt 0) {
    $latestSnapshot = [string]$snapshots[0].file
}

$index = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    latest_snapshot = $latestSnapshot
    snapshot_count = [int]$snapshots.Count
    snapshots = @($snapshots)
}

$index |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $indexPath -Encoding UTF8

Write-Host (
    "Dashboard index updated: " +
    $snapshots.Count.ToString() +
    " snapshot(s)."
) -ForegroundColor Green

return [pscustomobject]$index
'@

New-SafeFile ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" $indexScript

$showScript = @'
param(
    [string]$SnapshotId = "",
    [switch]$CreateNew
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

if ($CreateNew) {
    & ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" |
        Out-Null
}

& ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" |
    Out-Null

$index = Read-AIOfficeJsonFile `
    -Path ".\workspace\dashboard\dashboard-index.json"

if ($null -eq $index -or [int]$index.snapshot_count -eq 0) {
    throw "No dashboard snapshots are available. Run New-AIOfficeExecutiveSnapshot.ps1 first."
}

$snapshotFile = ""

if ([string]::IsNullOrWhiteSpace($SnapshotId)) {
    $snapshotFile = [string]$index.latest_snapshot
}
else {
    $match = @(
        $index.snapshots |
        Where-Object {
            $_.snapshot_id -eq $SnapshotId -or
            $_.file -eq $SnapshotId
        }
    ) | Select-Object -First 1

    if ($null -eq $match) {
        throw "Dashboard snapshot not found: $SnapshotId"
    }

    $snapshotFile = [string]$match.file
}

$snapshotPath = Join-Path `
    ".\workspace\dashboard\snapshots" `
    $snapshotFile

$snapshot = Read-AIOfficeJsonFile -Path $snapshotPath

if ($null -eq $snapshot) {
    throw "Dashboard snapshot could not be loaded: $snapshotPath"
}

Write-Host ""
Write-Host "AI OFFICE EXECUTIVE DASHBOARD" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Generated: " + [string]$snapshot.generated_at)
Write-Host (
    "Health: " +
    [string]$snapshot.overall_health.status.ToUpperInvariant() +
    " (" +
    [string]$snapshot.overall_health.score +
    "/100)"
)
Write-Host ""

Write-Host "EXECUTIVE SUMMARY" -ForegroundColor Yellow
Write-Host ([string]$snapshot.executive_summary)
Write-Host ""

Write-Host "KEY METRICS" -ForegroundColor Yellow
Write-Host (
    "Workflows : " +
    [string]$snapshot.metrics.workflows.total +
    " total | " +
    [string]$snapshot.metrics.workflows.active +
    " active | " +
    [string]$snapshot.metrics.workflows.blocked +
    " blocked | " +
    [string]$snapshot.metrics.workflows.overdue +
    " overdue"
)

Write-Host (
    "Approvals : " +
    [string]$snapshot.metrics.approvals.total +
    " total | " +
    [string]$snapshot.metrics.approvals.pending +
    " pending | " +
    [string]$snapshot.metrics.approvals.approved +
    " approved"
)

Write-Host (
    "Calendar  : " +
    [string]$snapshot.metrics.calendar.total +
    " total | " +
    [string]$snapshot.metrics.calendar.today +
    " today | " +
    [string]$snapshot.metrics.calendar.next_7_days +
    " next 7 days | " +
    [string]$snapshot.metrics.calendar.overdue +
    " overdue"
)

Write-Host (
    "Knowledge : " +
    [string]$snapshot.metrics.knowledge.total +
    " total | " +
    [string]$snapshot.metrics.knowledge.active +
    " active | " +
    [string]$snapshot.metrics.knowledge.stale +
    " stale"
)

Write-Host (
    "System    : " +
    [string]$snapshot.metrics.system.json_files_checked +
    " JSON checked | " +
    [string]$snapshot.metrics.system.invalid_json_files +
    " invalid | " +
    [string]$snapshot.metrics.system.required_components_missing +
    " components missing"
)

Write-Host ""
Write-Host "RISKS" -ForegroundColor Yellow

if (@($snapshot.risks).Count -eq 0) {
    Write-Host "No material risks detected."
}
else {
    foreach ($risk in @($snapshot.risks)) {
        Write-Host (
            "[" +
            [string]$risk.severity.ToUpperInvariant() +
            "] " +
            [string]$risk.title
        )

        Write-Host ("  " + [string]$risk.detail)
        Write-Host (
            "  Action: " +
            [string]$risk.recommended_action
        )
    }
}

Write-Host ""
Write-Host "RECOMMENDATIONS" -ForegroundColor Yellow

if (@($snapshot.recommendations).Count -eq 0) {
    Write-Host "No immediate corrective actions are required."
}
else {
    foreach ($recommendation in @($snapshot.recommendations)) {
        Write-Host ("- " + [string]$recommendation)
    }
}

Write-Host ""
return $snapshot
'@

New-SafeFile ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1" $showScript

$exportScript = @'
param(
    [string]$SnapshotId = "",
    [switch]$CreateNew,
    [switch]$Open
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

if ($CreateNew) {
    & ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" |
        Out-Null
}

& ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" |
    Out-Null

$index = Read-AIOfficeJsonFile `
    -Path ".\workspace\dashboard\dashboard-index.json"

if ($null -eq $index -or [int]$index.snapshot_count -eq 0) {
    throw "No dashboard snapshots are available."
}

$snapshotFile = ""

if ([string]::IsNullOrWhiteSpace($SnapshotId)) {
    $snapshotFile = [string]$index.latest_snapshot
}
else {
    $match = @(
        $index.snapshots |
        Where-Object {
            $_.snapshot_id -eq $SnapshotId -or
            $_.file -eq $SnapshotId
        }
    ) | Select-Object -First 1

    if ($null -eq $match) {
        throw "Dashboard snapshot not found: $SnapshotId"
    }

    $snapshotFile = [string]$match.file
}

$snapshotPath = Join-Path `
    ".\workspace\dashboard\snapshots" `
    $snapshotFile

$snapshot = Read-AIOfficeJsonFile -Path $snapshotPath

if ($null -eq $snapshot) {
    throw "Dashboard snapshot could not be loaded."
}

$statusClass = [string]$snapshot.overall_health.status
$riskRows = New-Object System.Collections.Generic.List[string]
$recommendationRows = New-Object System.Collections.Generic.List[string]

if (@($snapshot.risks).Count -eq 0) {
    $riskRows.Add(
        '<div class="empty">No material risks detected.</div>'
    )
}
else {
    foreach ($risk in @($snapshot.risks)) {
        $riskRows.Add(
            '<article class="risk ' +
            (ConvertTo-AIOfficeHtmlText $risk.severity) +
            '"><div class="risk-head"><span class="badge">' +
            (ConvertTo-AIOfficeHtmlText $risk.severity) +
            '</span><strong>' +
            (ConvertTo-AIOfficeHtmlText $risk.title) +
            '</strong></div><p>' +
            (ConvertTo-AIOfficeHtmlText $risk.detail) +
            '</p><p class="action">Action: ' +
            (ConvertTo-AIOfficeHtmlText $risk.recommended_action) +
            '</p></article>'
        )
    }
}

if (@($snapshot.recommendations).Count -eq 0) {
    $recommendationRows.Add(
        '<li>No immediate corrective actions are required.</li>'
    )
}
else {
    foreach ($recommendation in @($snapshot.recommendations)) {
        $recommendationRows.Add(
            '<li>' +
            (ConvertTo-AIOfficeHtmlText $recommendation) +
            '</li>'
        )
    }
}

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AI Office Executive Dashboard</title>
<style>
:root {
  --bg: #f3f5f7;
  --card: #ffffff;
  --text: #17212b;
  --muted: #5d6b78;
  --line: #d8dee4;
  --healthy: #167447;
  --attention: #986800;
  --critical: #b42318;
  --accent: #1e4f8a;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: "Segoe UI", Arial, sans-serif;
}
.wrap {
  max-width: 1240px;
  margin: 0 auto;
  padding: 28px;
}
header {
  background: #102a43;
  color: white;
  border-radius: 14px;
  padding: 28px;
  margin-bottom: 20px;
}
header h1 { margin: 0 0 8px; font-size: 30px; }
header p { margin: 0; opacity: .88; }
.health {
  margin-top: 20px;
  display: flex;
  align-items: center;
  gap: 18px;
}
.score {
  width: 94px;
  height: 94px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 27px;
  font-weight: 700;
  background: white;
}
.score.healthy { color: var(--healthy); }
.score.attention { color: var(--attention); }
.score.critical { color: var(--critical); }
.status { font-size: 20px; text-transform: uppercase; font-weight: 700; }
.summary, .section {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  padding: 22px;
  margin-bottom: 20px;
}
h2 { margin-top: 0; font-size: 20px; }
.metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit,minmax(210px,1fr));
  gap: 14px;
}
.metric {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  padding: 18px;
}
.metric h3 { margin: 0 0 13px; font-size: 16px; color: var(--accent); }
.metric .big { font-size: 30px; font-weight: 700; }
.metric p { margin: 7px 0 0; color: var(--muted); }
.risk {
  border: 1px solid var(--line);
  border-left-width: 6px;
  border-radius: 9px;
  padding: 16px;
  margin: 12px 0;
}
.risk.critical { border-left-color: var(--critical); }
.risk.high { border-left-color: #c2410c; }
.risk.medium { border-left-color: var(--attention); }
.risk.low { border-left-color: #1e6f9f; }
.risk-head { display: flex; gap: 10px; align-items: center; }
.badge {
  font-size: 11px;
  text-transform: uppercase;
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 3px 8px;
}
.risk p { margin: 10px 0 0; }
.action { color: var(--muted); }
.empty { color: var(--muted); }
footer {
  color: var(--muted);
  font-size: 12px;
  text-align: center;
  padding: 10px;
}
</style>
</head>
<body>
<div class="wrap">
<header>
  <h1>AI Office Executive Dashboard</h1>
  <p>Generated $(ConvertTo-AIOfficeHtmlText $snapshot.generated_at)</p>
  <div class="health">
    <div class="score $statusClass">$(ConvertTo-AIOfficeHtmlText $snapshot.overall_health.score)/100</div>
    <div>
      <div class="status">$(ConvertTo-AIOfficeHtmlText $snapshot.overall_health.status)</div>
      <div>$(ConvertTo-AIOfficeHtmlText $snapshot.overall_health.risk_count) operational risk(s)</div>
    </div>
  </div>
</header>

<section class="summary">
  <h2>Executive Summary</h2>
  <p>$(ConvertTo-AIOfficeHtmlText $snapshot.executive_summary)</p>
</section>

<section class="metrics">
  <article class="metric">
    <h3>Workflows</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.active)</div>
    <p>Active of $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.total) total</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.blocked) blocked · $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.workflows.overdue) overdue</p>
  </article>
  <article class="metric">
    <h3>Approvals</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.approvals.pending)</div>
    <p>Pending of $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.approvals.total) total</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.approvals.approved) approved</p>
  </article>
  <article class="metric">
    <h3>Calendar</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.calendar.next_7_days)</div>
    <p>Scheduled in next 7 days</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.calendar.today) today · $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.calendar.overdue) overdue</p>
  </article>
  <article class="metric">
    <h3>Knowledge</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.knowledge.active)</div>
    <p>Active of $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.knowledge.total) total</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.knowledge.stale) stale</p>
  </article>
  <article class="metric">
    <h3>System Health</h3>
    <div class="big">$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.system.json_files_checked)</div>
    <p>JSON files checked</p>
    <p>$(ConvertTo-AIOfficeHtmlText $snapshot.metrics.system.invalid_json_files) invalid · $(ConvertTo-AIOfficeHtmlText $snapshot.metrics.system.required_components_missing) missing components</p>
  </article>
</section>

<section class="section">
  <h2>Risks</h2>
  $($riskRows -join "`r`n")
</section>

<section class="section">
  <h2>Recommendations</h2>
  <ul>
    $($recommendationRows -join "`r`n")
  </ul>
</section>

<footer>
Snapshot $(ConvertTo-AIOfficeHtmlText $snapshot.snapshot_id)
</footer>
</div>
</body>
</html>
"@

$reportFile = (
    [System.IO.Path]::GetFileNameWithoutExtension($snapshotFile) +
    ".html"
)

$reportPath = Join-Path `
    ".\workspace\dashboard\reports" `
    $reportFile

Set-Content `
    -LiteralPath $reportPath `
    -Value $html `
    -Encoding UTF8

Write-Host "Executive dashboard HTML report created: $reportPath" `
    -ForegroundColor Green

if ($Open) {
    Start-Process $reportPath
}

return $reportPath
'@

New-SafeFile ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1" $exportScript

$archiveScript = @'
param(
    [int]$OlderThanDays = 90,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$snapshotFolder = ".\workspace\dashboard\snapshots"
$archiveFolder = ".\workspace\dashboard\archive"

if (-not (Test-Path -LiteralPath $archiveFolder)) {
    New-Item -ItemType Directory -Path $archiveFolder -Force |
        Out-Null
}

$candidates = @(
    Get-ChildItem `
        -LiteralPath $snapshotFolder `
        -Filter "DSH-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff }
)

foreach ($file in $candidates) {
    $destination = Join-Path $archiveFolder $file.Name

    if ($WhatIf) {
        Write-Host (
            "[WHATIF] Move " +
            $file.FullName +
            " to " +
            $destination
        )
    }
    else {
        Move-Item `
            -LiteralPath $file.FullName `
            -Destination $destination `
            -Force

        Write-Host (
            "[ARCHIVED] " +
            $file.Name
        ) -ForegroundColor Green
    }
}

if (-not $WhatIf) {
    & ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" |
        Out-Null
}

Write-Host (
    $candidates.Count.ToString() +
    " snapshot(s) selected for archive."
)
'@

New-SafeFile ".\scripts\dashboard\Archive-AIOfficeDashboardSnapshots.ps1" $archiveScript

$testScript = @'
param()

$ErrorActionPreference = "Stop"

$root = Resolve-Path (
    Join-Path $PSScriptRoot "..\.."
)

Set-Location $root.Path

Write-Host ""
Write-Host "Testing AI Office executive dashboard..." `
    -ForegroundColor Cyan
Write-Host ""

$errors = New-Object System.Collections.Generic.List[string]

$jsonFiles = @(
    ".\config\dashboard\dashboard-policy.json",
    ".\config\dashboard\executive-dashboard-schema.json",
    ".\workspace\dashboard\dashboard-index.json",
    ".\workspace\templates\executive-dashboard-template.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $file" `
            -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $file" `
            -ForegroundColor Red

        $errors.Add(
            "Invalid JSON: " +
            $file +
            " - " +
            $_.Exception.Message
        )
    }
}

$requiredScripts = @(
    ".\scripts\dashboard\AIOfficeDashboard.Common.ps1",
    ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1",
    ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1",
    ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1",
    ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1",
    ".\scripts\dashboard\Archive-AIOfficeDashboardSnapshots.ps1",
    ".\scripts\dashboard\Test-AIOfficeExecutiveDashboard.ps1"
)

foreach ($script in $requiredScripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" `
            -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $script" `
            -ForegroundColor Red

        $errors.Add(
            "Missing script: " +
            $script
        )
    }
}

try {
    $snapshot = & `
        ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1" `
        -PassThru

    if (
        $null -ne $snapshot -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$snapshot.snapshot_id
        ) -and
        [int]$snapshot.overall_health.score -ge 0 -and
        [int]$snapshot.overall_health.score -le 100
    ) {
        Write-Host (
            "[SNAPSHOT OK] " +
            [string]$snapshot.snapshot_id +
            " | Health " +
            [string]$snapshot.overall_health.score +
            "/100"
        ) -ForegroundColor Green
    }
    else {
        throw "Snapshot did not contain expected values."
    }
}
catch {
    Write-Host "[SNAPSHOT ERR] Snapshot generation failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $errors.Add(
        "Snapshot generation failed: " +
        $_.Exception.Message
    )
}

try {
    $index = & `
        ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1"

    if (
        $null -ne $index -and
        [int]$index.snapshot_count -gt 0
    ) {
        Write-Host (
            "[INDEX OK   ] " +
            [string]$index.snapshot_count +
            " dashboard snapshot(s)"
        ) -ForegroundColor Green
    }
    else {
        throw "Dashboard index did not contain a snapshot."
    }
}
catch {
    Write-Host "[INDEX ERR  ] Dashboard indexing failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $errors.Add(
        "Dashboard indexing failed: " +
        $_.Exception.Message
    )
}

try {
    $reportPath = & `
        ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1"

    if (
        -not [string]::IsNullOrWhiteSpace(
            [string]$reportPath
        ) -and
        (Test-Path -LiteralPath $reportPath -PathType Leaf)
    ) {
        Write-Host (
            "[EXPORT OK  ] " +
            [string]$reportPath
        ) -ForegroundColor Green
    }
    else {
        throw "HTML report was not created."
    }
}
catch {
    Write-Host "[EXPORT ERR ] HTML report generation failed." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    $errors.Add(
        "HTML report generation failed: " +
        $_.Exception.Message
    )
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $errors.Count.ToString() +
        " executive dashboard error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All executive dashboard checks passed." `
    -ForegroundColor Green
'@

New-SafeFile ".\scripts\dashboard\Test-AIOfficeExecutiveDashboard.ps1" $testScript

$guide = @'
# AI Office Executive Dashboard

Package 12 adds a consolidated executive dashboard across the AI Office repository.

## Core capabilities

- Creates timestamped operational snapshots
- Summarizes workflows, approvals, calendar events, knowledge records, and system health
- Calculates a 0–100 operational health score
- Detects overdue work, blocked workflows, pending approvals, stale knowledge, invalid JSON, and missing components
- Produces console dashboards
- Exports standalone HTML reports
- Maintains a searchable snapshot index
- Archives old snapshots

## Create a snapshot

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1"
```

## Show the latest dashboard

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1"
```

Create a new snapshot immediately before displaying it:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Show-AIOfficeExecutiveDashboard.ps1" `
    -CreateNew
```

## Export an HTML dashboard

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1" `
    -CreateNew `
    -Open
```

Reports are stored in:

```text
workspace\dashboard\reports
```

## Archive old snapshots

Preview:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Archive-AIOfficeDashboardSnapshots.ps1" `
    -OlderThanDays 90 `
    -WhatIf
```

Archive:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Archive-AIOfficeDashboardSnapshots.ps1" `
    -OlderThanDays 90
```

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Test-AIOfficeExecutiveDashboard.ps1"
```

Expected result:

```text
All executive dashboard checks passed.
```

## Data-source behavior

The dashboard automatically checks for existing AI Office indexes. Missing optional data sources are treated as empty rather than fatal. Invalid JSON and missing Package 12 components are treated as system risks.
'@

New-SafeFile ".\docs\Executive-Dashboard-Guide.md" $guide

Write-Host ""
Write-Host "Validating Package 12 JSON files..." `
    -ForegroundColor Cyan

$jsonValidationFiles = @(
    ".\config\dashboard\dashboard-policy.json",
    ".\config\dashboard\executive-dashboard-schema.json",
    ".\workspace\dashboard\dashboard-index.json",
    ".\workspace\templates\executive-dashboard-template.json"
)

foreach ($jsonFile in $jsonValidationFiles) {
    try {
        Get-Content -LiteralPath $jsonFile -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $jsonFile" `
            -ForegroundColor Green
    }
    catch {
        throw (
            "Package 12 JSON validation failed for " +
            $jsonFile +
            ": " +
            $_.Exception.Message
        )
    }
}

# Preserve a copy of this installer inside the repository.
try {
    $installerSource = $MyInvocation.MyCommand.Path

    if (
        -not [string]::IsNullOrWhiteSpace($installerSource) -and
        (Test-Path -LiteralPath $installerSource -PathType Leaf)
    ) {
        $installerDestination = Join-Path `
            $expectedRepository `
            "Installers\AI-Office-Package-12-Install.ps1"

        $sourceFullPath = [System.IO.Path]::GetFullPath(
            $installerSource
        )

        $destinationFullPath = [System.IO.Path]::GetFullPath(
            $installerDestination
        )

        if ($sourceFullPath -ne $destinationFullPath) {
            Copy-Item `
                -LiteralPath $installerSource `
                -Destination $installerDestination `
                -Force

            Write-Host (
                "[COPIED ] Installer saved to " +
                $installerDestination
            ) -ForegroundColor Green
        }
        else {
            Write-Host (
                "[EXISTS ] Installer is already in the Installers folder."
            ) -ForegroundColor DarkGray
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
Write-Host "AI Office Package 12 installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host ""
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\dashboard\Test-AIOfficeExecutiveDashboard.ps1"'
Write-Host ""
