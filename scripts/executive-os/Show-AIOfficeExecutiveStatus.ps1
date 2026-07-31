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
