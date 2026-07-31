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
    risks = @($risks | ForEach-Object { $_ })
    recommendations = @($recommendations.ToArray() | Select-Object -Unique)
    sources = @($sources | ForEach-Object { $_ })
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

