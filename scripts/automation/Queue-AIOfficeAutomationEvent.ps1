param(
    [Parameter(Mandatory=$true)][string]$TriggerType,
    [Parameter(Mandatory=$true)][string]$Source,
    [string]$PayloadJson = "{}",
    [string]$CorrelationId = "",
    [string]$ParentEventId = "",
    [int]$Depth = 0
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$policy = Read-AIOfficeAutomationJson -Path ".\config\automation\automation-policy.json"

if (@($policy.allowed_trigger_types) -notcontains $TriggerType) {
    throw "Trigger type is not allowed: $TriggerType"
}

if ($Depth -gt [int]$policy.max_execution_depth) {
    throw "Maximum automation execution depth exceeded."
}

try {
    $payload = $PayloadJson | ConvertFrom-Json
}
catch {
    throw "PayloadJson is not valid JSON: $($_.Exception.Message)"
}

$eventId = New-AIOfficeAutomationId -Prefix "EVT"

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = $eventId
}

$event = [ordered]@{
    event_id = $eventId
    trigger_type = $TriggerType
    created_at = (Get-Date).ToString("o")
    source = $Source
    payload = $payload
    correlation_id = $CorrelationId
    parent_event_id = $ParentEventId
    depth = $Depth
}

$path = Join-Path ".\workspace\automation\queued-events" ($eventId + ".json")
Write-AIOfficeAutomationJson -Value $event -Path $path

& ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1" | Out-Null

Write-Host "Automation event queued: $eventId" -ForegroundColor Green
return [pscustomobject]$event
