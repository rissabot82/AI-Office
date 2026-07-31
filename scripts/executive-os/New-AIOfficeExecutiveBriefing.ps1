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
