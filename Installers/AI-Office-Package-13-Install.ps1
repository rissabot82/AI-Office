# ============================================================
# AI Office Package 13
# Automation Engine
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
    ".\config\automation",
    ".\workspace\automation",
    ".\workspace\automation\rules",
    ".\workspace\automation\execution-log",
    ".\workspace\automation\queued-events",
    ".\workspace\automation\archived-events",
    ".\workspace\automation\dead-letter",
    ".\workspace\automation\state",
    ".\scripts\automation",
    ".\docs",
    ".\Installers"
)

foreach ($folder in $folders) {
    New-SafeDirectory -Path $folder
}

$policy = @'
{
  "version": "1.0.0",
  "engine_name": "AI Office Automation Engine",
  "enabled": true,
  "default_timezone": "America/Chicago",
  "max_execution_depth": 5,
  "max_actions_per_rule": 20,
  "max_events_per_run": 100,
  "duplicate_suppression_minutes": 30,
  "retry_limit": 2,
  "execution_timeout_seconds": 120,
  "require_approval_for_high_impact": true,
  "high_impact_actions": [
    "execute_script",
    "archive_record",
    "change_priority",
    "create_child_workflow"
  ],
  "allowed_trigger_types": [
    "manual",
    "workflow_created",
    "workflow_updated",
    "workflow_completed",
    "workflow_approved",
    "workflow_rejected",
    "calendar_due",
    "calendar_overdue",
    "knowledge_added",
    "knowledge_updated",
    "dashboard_health_below",
    "file_created",
    "file_modified",
    "daily_schedule",
    "weekly_schedule",
    "monthly_schedule"
  ],
  "allowed_action_types": [
    "create_workflow",
    "create_child_workflow",
    "assign_owner",
    "change_priority",
    "request_approval",
    "generate_report",
    "generate_dashboard_snapshot",
    "send_internal_notification",
    "archive_record",
    "update_knowledge",
    "execute_script",
    "queue_event",
    "call_component",
    "write_log"
  ]
}
'@

New-SafeFile ".\config\automation\automation-policy.json" $policy

$ruleSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/automation-rule-schema.json",
  "title": "AI Office Automation Rule",
  "type": "object",
  "required": [
    "rule_id",
    "name",
    "enabled",
    "priority",
    "trigger",
    "conditions",
    "actions",
    "created_at",
    "updated_at"
  ],
  "properties": {
    "rule_id": {
      "type": "string",
      "pattern": "^AUT-[A-Z0-9-]+$"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "description": {
      "type": "string"
    },
    "enabled": {
      "type": "boolean"
    },
    "priority": {
      "type": "integer",
      "minimum": 1,
      "maximum": 1000
    },
    "trigger": {
      "type": "object",
      "required": [
        "type"
      ],
      "properties": {
        "type": {
          "type": "string"
        },
        "schedule": {
          "type": "string"
        },
        "source": {
          "type": "string"
        },
        "event_name": {
          "type": "string"
        }
      }
    },
    "conditions": {
      "type": "array"
    },
    "actions": {
      "type": "array",
      "minItems": 1
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    }
  }
}
'@

New-SafeFile ".\config\automation\automation-rule-schema.json" $ruleSchema

$triggerSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/automation-trigger-schema.json",
  "title": "AI Office Automation Event",
  "type": "object",
  "required": [
    "event_id",
    "trigger_type",
    "created_at",
    "source",
    "payload",
    "depth"
  ],
  "properties": {
    "event_id": {
      "type": "string",
      "pattern": "^EVT-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "trigger_type": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "source": {
      "type": "string"
    },
    "payload": {
      "type": "object"
    },
    "correlation_id": {
      "type": "string"
    },
    "parent_event_id": {
      "type": "string"
    },
    "depth": {
      "type": "integer",
      "minimum": 0
    }
  }
}
'@

New-SafeFile ".\config\automation\automation-trigger-schema.json" $triggerSchema

$index = @'
{
  "version": "1.0.0",
  "updated_at": "",
  "rule_count": 0,
  "enabled_rule_count": 0,
  "queued_event_count": 0,
  "execution_count": 0,
  "rules": []
}
'@

New-SafeFile ".\workspace\automation\automation-index.json" $index

$state = @'
{
  "version": "1.0.0",
  "last_run_at": "",
  "processed_event_ids": [],
  "recent_fingerprints": []
}
'@

New-SafeFile ".\workspace\automation\state\engine-state.json" $state

$template = @'
{
  "rule_id": "AUT-EXAMPLE",
  "name": "Example automation rule",
  "description": "Replace this example with an operational rule.",
  "enabled": false,
  "priority": 100,
  "trigger": {
    "type": "manual",
    "source": "user"
  },
  "conditions": [],
  "actions": [
    {
      "type": "write_log",
      "message": "Example automation executed."
    }
  ],
  "created_at": "",
  "updated_at": ""
}
'@

New-SafeFile ".\workspace\templates\automation-rule-template.json" $template

$common = @'
$script:AIOfficeAutomationRoot = $null

function Get-AIOfficeAutomationRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeAutomationRoot)) {
        return $script:AIOfficeAutomationRoot
    }

    $resolved = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $script:AIOfficeAutomationRoot = $resolved.Path
    return $script:AIOfficeAutomationRoot
}

function Read-AIOfficeAutomationJson {
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

function Write-AIOfficeAutomationJson {
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
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function ConvertTo-AIOfficeAutomationArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function Get-AIOfficeAutomationProperty {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory=$true)][string[]]$Names,
        [AllowNull()]$Default = $null
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

function New-AIOfficeAutomationId {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("AUT","EVT","RUN")]
        [string]$Prefix
    )

    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return $Prefix + "-" + $stamp + "-" + $suffix
}

function Get-AIOfficeAutomationFingerprint {
    param(
        [Parameter(Mandatory=$true)][string]$TriggerType,
        [Parameter(Mandatory=$true)][string]$Source,
        [AllowNull()]$Payload
    )

    $payloadText = ""

    if ($null -ne $Payload) {
        $payloadText = $Payload | ConvertTo-Json -Depth 20 -Compress
    }

    $inputText = $TriggerType + "|" + $Source + "|" + $payloadText
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputText)
    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    return ([System.BitConverter]::ToString($hash)).Replace("-","")
}

function Test-AIOfficeAutomationCondition {
    param(
        [Parameter(Mandatory=$true)]$Condition,
        [Parameter(Mandatory=$true)]$Event
    )

    $field = [string](Get-AIOfficeAutomationProperty -Object $Condition -Names @("field"))
    $operator = [string](Get-AIOfficeAutomationProperty -Object $Condition -Names @("operator") -Default "equals")
    $expected = Get-AIOfficeAutomationProperty -Object $Condition -Names @("value")

    if ([string]::IsNullOrWhiteSpace($field)) {
        return $true
    }

    $actual = $Event.payload

    foreach ($segment in $field.Split(".")) {
        if ($null -eq $actual) {
            break
        }

        $property = $actual.PSObject.Properties[$segment]

        if ($null -eq $property) {
            $actual = $null
            break
        }

        $actual = $property.Value
    }

    switch ($operator.ToLowerInvariant()) {
        "equals" { return [string]$actual -eq [string]$expected }
        "not_equals" { return [string]$actual -ne [string]$expected }
        "contains" { return ([string]$actual).Contains([string]$expected) }
        "greater_than" { return [double]$actual -gt [double]$expected }
        "less_than" { return [double]$actual -lt [double]$expected }
        "exists" { return $null -ne $actual }
        "not_exists" { return $null -eq $actual }
        default { throw "Unsupported condition operator: $operator" }
    }
}

function Add-AIOfficeAutomationExecutionLog {
    param([Parameter(Mandatory=$true)]$Record)

    $root = Get-AIOfficeAutomationRoot
    $fileName = [string]$Record.run_id + ".json"
    $path = Join-Path $root ("workspace\automation\execution-log\" + $fileName)

    Write-AIOfficeAutomationJson -Value $Record -Path $path
    return $path
}
'@

New-SafeFile ".\scripts\automation\AIOfficeAutomation.Common.ps1" $common

$newRule = @'
param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$TriggerType,
    [Parameter(Mandatory=$true)][string]$ActionsJson,
    [string]$Description = "",
    [string]$ConditionsJson = "[]",
    [int]$Priority = 100,
    [switch]$Disabled,
    [string]$RuleId = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$policy = Read-AIOfficeAutomationJson -Path ".\config\automation\automation-policy.json"

if ($null -eq $policy) {
    throw "Automation policy could not be loaded."
}

if (@($policy.allowed_trigger_types) -notcontains $TriggerType) {
    throw "Trigger type is not allowed: $TriggerType"
}

try {
    $actions = $ActionsJson | ConvertFrom-Json
}
catch {
    throw "ActionsJson is not valid JSON: $($_.Exception.Message)"
}

try {
    $conditions = $ConditionsJson | ConvertFrom-Json
}
catch {
    throw "ConditionsJson is not valid JSON: $($_.Exception.Message)"
}

$actions = ConvertTo-AIOfficeAutomationArray $actions
$conditions = ConvertTo-AIOfficeAutomationArray $conditions

if ($actions.Count -eq 0) {
    throw "At least one action is required."
}

if ($actions.Count -gt [int]$policy.max_actions_per_rule) {
    throw "Rule exceeds the maximum allowed action count."
}

foreach ($action in $actions) {
    $actionType = [string](Get-AIOfficeAutomationProperty -Object $action -Names @("type"))

    if ([string]::IsNullOrWhiteSpace($actionType)) {
        throw "Each action must include a type."
    }

    if (@($policy.allowed_action_types) -notcontains $actionType) {
        throw "Action type is not allowed: $actionType"
    }
}

if ([string]::IsNullOrWhiteSpace($RuleId)) {
    $RuleId = "AUT-" + ([guid]::NewGuid().ToString("N").Substring(0,10)).ToUpperInvariant()
}

$now = (Get-Date).ToString("o")

$rule = [ordered]@{
    rule_id = $RuleId
    name = $Name
    description = $Description
    enabled = (-not $Disabled)
    priority = $Priority
    trigger = [ordered]@{
        type = $TriggerType
        source = "manual"
    }
    conditions = @($conditions | ForEach-Object { $_ })
    actions = @($actions | ForEach-Object { $_ })
    created_at = $now
    updated_at = $now
}

$path = Join-Path ".\workspace\automation\rules" ($RuleId + ".json")

if (Test-Path -LiteralPath $path -PathType Leaf) {
    throw "Automation rule already exists: $RuleId"
}

Write-AIOfficeAutomationJson -Value $rule -Path $path

& ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1" | Out-Null

Write-Host "Automation rule created: $RuleId" -ForegroundColor Green
return [pscustomobject]$rule
'@

New-SafeFile ".\scripts\automation\New-AIOfficeAutomationRule.ps1" $newRule

$updateIndex = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$ruleFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\automation\rules" `
        -Filter "AUT-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$rules = New-Object System.Collections.Generic.List[object]

foreach ($file in $ruleFiles) {
    $rule = Read-AIOfficeAutomationJson -Path $file.FullName

    if ($null -ne $rule) {
        $rules.Add([ordered]@{
            rule_id = [string]$rule.rule_id
            name = [string]$rule.name
            enabled = [bool]$rule.enabled
            priority = [int]$rule.priority
            trigger_type = [string]$rule.trigger.type
            file = $file.Name
            updated_at = [string]$rule.updated_at
        })
    }
}

$queueCount = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\automation\queued-events" `
        -Filter "EVT-*.json" `
        -File `
        -ErrorAction SilentlyContinue
).Count

$executionCount = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\automation\execution-log" `
        -Filter "RUN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
).Count

$enabledCount = @(
    $rules | Where-Object { $_.enabled -eq $true }
).Count

$index = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    rule_count = [int]$rules.Count
    enabled_rule_count = [int]$enabledCount
    queued_event_count = [int]$queueCount
    execution_count = [int]$executionCount
    rules = @($rules | Sort-Object priority, rule_id | ForEach-Object { $_ })
}

Write-AIOfficeAutomationJson `
    -Value $index `
    -Path ".\workspace\automation\automation-index.json"

Write-Host (
    "Automation index updated: " +
    $rules.Count.ToString() +
    " rule(s), " +
    $queueCount.ToString() +
    " queued event(s)."
) -ForegroundColor Green

return [pscustomobject]$index
'@

New-SafeFile ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1" $updateIndex

$queueEvent = @'
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
'@

New-SafeFile ".\scripts\automation\Queue-AIOfficeAutomationEvent.ps1" $queueEvent

$toggle = @'
param(
    [Parameter(Mandatory=$true)][string]$RuleId,
    [Parameter(Mandatory=$true)][bool]$Enabled
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$path = Join-Path ".\workspace\automation\rules" ($RuleId + ".json")
$rule = Read-AIOfficeAutomationJson -Path $path

if ($null -eq $rule) {
    throw "Automation rule not found: $RuleId"
}

$rule.enabled = $Enabled
$rule.updated_at = (Get-Date).ToString("o")

Write-AIOfficeAutomationJson -Value $rule -Path $path
& ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1" | Out-Null

$state = if ($Enabled) { "enabled" } else { "disabled" }

Write-Host (
    "Automation rule " +
    $RuleId +
    " " +
    $state +
    "."
) -ForegroundColor Green
'@

New-SafeFile ".\scripts\automation\Set-AIOfficeAutomationRuleState.ps1" $toggle

$enable = @'
param([Parameter(Mandatory=$true)][string]$RuleId)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "Set-AIOfficeAutomationRuleState.ps1") `
    -RuleId $RuleId `
    -Enabled $true
'@

New-SafeFile ".\scripts\automation\Enable-AIOfficeAutomationRule.ps1" $enable

$disable = @'
param([Parameter(Mandatory=$true)][string]$RuleId)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "Set-AIOfficeAutomationRuleState.ps1") `
    -RuleId $RuleId `
    -Enabled $false
'@

New-SafeFile ".\scripts\automation\Disable-AIOfficeAutomationRule.ps1" $disable

$engine = @'
param(
    [switch]$DryRun,
    [int]$MaxEvents = 0
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$policy = Read-AIOfficeAutomationJson -Path ".\config\automation\automation-policy.json"

if ($null -eq $policy) {
    throw "Automation policy could not be loaded."
}

if (-not [bool]$policy.enabled) {
    Write-Host "Automation engine is disabled." -ForegroundColor Yellow
    return
}

if ($MaxEvents -le 0) {
    $MaxEvents = [int]$policy.max_events_per_run
}

$statePath = ".\workspace\automation\state\engine-state.json"
$state = Read-AIOfficeAutomationJson -Path $statePath

if ($null -eq $state) {
    $state = [pscustomobject]@{
        version = "1.0.0"
        last_run_at = ""
        processed_event_ids = @()
        recent_fingerprints = @()
    }
}

$recentFingerprints = New-Object System.Collections.Generic.List[object]

foreach ($entry in (ConvertTo-AIOfficeAutomationArray $state.recent_fingerprints)) {
    $timestamp = ConvertTo-DateTimeSafe $entry.timestamp

    if ($null -ne $timestamp -and
        $timestamp -ge (Get-Date).AddMinutes(-[int]$policy.duplicate_suppression_minutes)) {
        $recentFingerprints.Add($entry)
    }
}

function ConvertTo-DateTimeSafe {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $parsed = [datetime]::MinValue

    if ([datetime]::TryParse([string]$Value, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

$rules = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\automation\rules" `
        -Filter "AUT-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        Read-AIOfficeAutomationJson -Path $_.FullName
    } |
    Where-Object {
        $null -ne $_ -and $_.enabled -eq $true
    } |
    Sort-Object priority, rule_id
)

$events = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\automation\queued-events" `
        -Filter "EVT-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object CreationTime |
    Select-Object -First $MaxEvents
)

$processedIds = New-Object System.Collections.Generic.List[string]

foreach ($existing in (ConvertTo-AIOfficeAutomationArray $state.processed_event_ids)) {
    $processedIds.Add([string]$existing)
}

foreach ($eventFile in $events) {
    $event = Read-AIOfficeAutomationJson -Path $eventFile.FullName

    if ($null -eq $event) {
        Move-Item `
            -LiteralPath $eventFile.FullName `
            -Destination (Join-Path ".\workspace\automation\dead-letter" $eventFile.Name) `
            -Force

        continue
    }

    if ([int]$event.depth -gt [int]$policy.max_execution_depth) {
        Move-Item `
            -LiteralPath $eventFile.FullName `
            -Destination (Join-Path ".\workspace\automation\dead-letter" $eventFile.Name) `
            -Force

        continue
    }

    $fingerprint = Get-AIOfficeAutomationFingerprint `
        -TriggerType ([string]$event.trigger_type) `
        -Source ([string]$event.source) `
        -Payload $event.payload

    $isDuplicate = @(
        $recentFingerprints |
        Where-Object { $_.fingerprint -eq $fingerprint }
    ).Count -gt 0

    if ($isDuplicate) {
        Move-Item `
            -LiteralPath $eventFile.FullName `
            -Destination (Join-Path ".\workspace\automation\archived-events" $eventFile.Name) `
            -Force

        continue
    }

    $matchingRules = @(
        $rules |
        Where-Object {
            [string]$_.trigger.type -eq [string]$event.trigger_type
        }
    )

    foreach ($rule in $matchingRules) {
        $conditionsPassed = $true

        foreach ($condition in (ConvertTo-AIOfficeAutomationArray $rule.conditions)) {
            if (-not (Test-AIOfficeAutomationCondition -Condition $condition -Event $event)) {
                $conditionsPassed = $false
                break
            }
        }

        if (-not $conditionsPassed) {
            continue
        }

        $runId = New-AIOfficeAutomationId -Prefix "RUN"
        $started = Get-Date
        $actionResults = New-Object System.Collections.Generic.List[object]
        $success = $true
        $errorMessage = ""

        try {
            foreach ($action in (ConvertTo-AIOfficeAutomationArray $rule.actions)) {
                $actionType = [string]$action.type

                if ($DryRun) {
                    $actionResults.Add([ordered]@{
                        action_type = $actionType
                        status = "dry_run"
                        message = "Action not executed."
                    })

                    continue
                }

                switch ($actionType) {
                    "write_log" {
                        $message = [string](
                            Get-AIOfficeAutomationProperty `
                                -Object $action `
                                -Names @("message") `
                                -Default "Automation log entry."
                        )

                        $actionResults.Add([ordered]@{
                            action_type = $actionType
                            status = "success"
                            message = $message
                        })
                    }

                    "generate_dashboard_snapshot" {
                        $scriptPath = ".\scripts\dashboard\New-AIOfficeExecutiveSnapshot.ps1"

                        if (-not (Test-Path -LiteralPath $scriptPath)) {
                            throw "Dashboard snapshot script was not found."
                        }

                        & $scriptPath | Out-Null

                        $actionResults.Add([ordered]@{
                            action_type = $actionType
                            status = "success"
                            message = "Dashboard snapshot generated."
                        })
                    }

                    "generate_report" {
                        $scriptPath = ".\scripts\dashboard\Export-AIOfficeExecutiveDashboard.ps1"

                        if (-not (Test-Path -LiteralPath $scriptPath)) {
                            throw "Dashboard export script was not found."
                        }

                        $reportPath = & $scriptPath -CreateNew

                        $actionResults.Add([ordered]@{
                            action_type = $actionType
                            status = "success"
                            message = [string]$reportPath
                        })
                    }

                    "queue_event" {
                        $childTrigger = [string](
                            Get-AIOfficeAutomationProperty `
                                -Object $action `
                                -Names @("trigger_type")
                        )

                        $childSource = [string](
                            Get-AIOfficeAutomationProperty `
                                -Object $action `
                                -Names @("source") `
                                -Default $rule.rule_id
                        )

                        $childPayload = Get-AIOfficeAutomationProperty `
                            -Object $action `
                            -Names @("payload") `
                            -Default ([pscustomobject]@{})

                        $childPayloadJson = $childPayload |
                            ConvertTo-Json -Depth 20 -Compress

                        & ".\scripts\automation\Queue-AIOfficeAutomationEvent.ps1" `
                            -TriggerType $childTrigger `
                            -Source $childSource `
                            -PayloadJson $childPayloadJson `
                            -CorrelationId ([string]$event.correlation_id) `
                            -ParentEventId ([string]$event.event_id) `
                            -Depth ([int]$event.depth + 1) |
                            Out-Null

                        $actionResults.Add([ordered]@{
                            action_type = $actionType
                            status = "success"
                            message = "Child event queued."
                        })
                    }

                    "execute_script" {
                        $scriptPath = [string](
                            Get-AIOfficeAutomationProperty `
                                -Object $action `
                                -Names @("script_path")
                        )

                        if ([string]::IsNullOrWhiteSpace($scriptPath)) {
                            throw "execute_script action requires script_path."
                        }

                        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
                            throw "Automation script was not found: $scriptPath"
                        }

                        & $scriptPath | Out-Null

                        $actionResults.Add([ordered]@{
                            action_type = $actionType
                            status = "success"
                            message = "Script executed: $scriptPath"
                        })
                    }

                    default {
                        $actionResults.Add([ordered]@{
                            action_type = $actionType
                            status = "recorded"
                            message = "Action recorded for downstream integration."
                        })
                    }
                }
            }
        }
        catch {
            $success = $false
            $errorMessage = $_.Exception.Message
        }

        $ended = Get-Date

        $record = [ordered]@{
            run_id = $runId
            rule_id = [string]$rule.rule_id
            event_id = [string]$event.event_id
            correlation_id = [string]$event.correlation_id
            trigger_type = [string]$event.trigger_type
            started_at = $started.ToString("o")
            completed_at = $ended.ToString("o")
            duration_ms = [int](($ended - $started).TotalMilliseconds)
            dry_run = [bool]$DryRun
            success = [bool]$success
            error = $errorMessage
            action_results = @($actionResults | ForEach-Object { $_ })
        }

        Add-AIOfficeAutomationExecutionLog -Record $record | Out-Null
    }

    $processedIds.Add([string]$event.event_id)

    $recentFingerprints.Add([ordered]@{
        fingerprint = $fingerprint
        timestamp = (Get-Date).ToString("o")
    })

    Move-Item `
        -LiteralPath $eventFile.FullName `
        -Destination (Join-Path ".\workspace\automation\archived-events" $eventFile.Name) `
        -Force
}

$newState = [ordered]@{
    version = "1.0.0"
    last_run_at = (Get-Date).ToString("o")
    processed_event_ids = @($processedIds | Select-Object -Last 1000)
    recent_fingerprints = @($recentFingerprints | ForEach-Object { $_ })
}

Write-AIOfficeAutomationJson -Value $newState -Path $statePath

& ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1" | Out-Null

Write-Host (
    "Automation engine processed " +
    $events.Count.ToString() +
    " event(s)."
) -ForegroundColor Green
'@

New-SafeFile ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1" $engine

$processQueue = @'
param(
    [switch]$DryRun,
    [int]$MaxEvents = 0
)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "Invoke-AIOfficeAutomationEngine.ps1") `
    -DryRun:$DryRun `
    -MaxEvents $MaxEvents
'@

New-SafeFile ".\scripts\automation\Process-AIOfficeAutomationQueue.ps1" $processQueue

$archive = @'
param(
    [int]$OlderThanDays = 30,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$sourceFolders = @(
    ".\workspace\automation\execution-log",
    ".\workspace\automation\archived-events"
)

$archiveRoot = ".\workspace\automation\archive"

if (-not (Test-Path -LiteralPath $archiveRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
}

$count = 0

foreach ($source in $sourceFolders) {
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        continue
    }

    $destination = Join-Path $archiveRoot (Split-Path $source -Leaf)

    if (-not (Test-Path -LiteralPath $destination -PathType Container)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }

    $files = @(
        Get-ChildItem `
            -LiteralPath $source `
            -Filter "*.json" `
            -File `
            -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    )

    foreach ($file in $files) {
        $count++

        if ($WhatIf) {
            Write-Host (
                "[WHATIF] Archive " +
                $file.FullName
            )
        }
        else {
            Move-Item `
                -LiteralPath $file.FullName `
                -Destination (Join-Path $destination $file.Name) `
                -Force

            Write-Host (
                "[ARCHIVED] " +
                $file.Name
            ) -ForegroundColor Green
        }
    }
}

Write-Host (
    $count.ToString() +
    " automation file(s) selected for archive."
)
'@

New-SafeFile ".\scripts\automation\Archive-AIOfficeAutomationEvents.ps1" $archive

$testRules = @'
param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$policy = Read-AIOfficeAutomationJson -Path ".\config\automation\automation-policy.json"
$errors = New-Object System.Collections.Generic.List[string]

$files = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\automation\rules" `
        -Filter "AUT-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

foreach ($file in $files) {
    $rule = Read-AIOfficeAutomationJson -Path $file.FullName

    if ($null -eq $rule) {
        $errors.Add("Invalid rule JSON: " + $file.FullName)
        continue
    }

    if ([string]::IsNullOrWhiteSpace([string]$rule.rule_id)) {
        $errors.Add("Missing rule_id: " + $file.FullName)
    }

    if (@($policy.allowed_trigger_types) -notcontains [string]$rule.trigger.type) {
        $errors.Add("Unsupported trigger type in " + $file.Name)
    }

    foreach ($action in (ConvertTo-AIOfficeAutomationArray $rule.actions)) {
        if (@($policy.allowed_action_types) -notcontains [string]$action.type) {
            $errors.Add(
                "Unsupported action type " +
                [string]$action.type +
                " in " +
                $file.Name
            )
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($errorItem in $errors) {
        Write-Host "[RULE ERROR] $errorItem" -ForegroundColor Red
    }

    exit 1
}

Write-Host (
    "All " +
    $files.Count.ToString() +
    " automation rule(s) passed validation."
) -ForegroundColor Green
'@

New-SafeFile ".\scripts\automation\Test-AIOfficeAutomationRules.ps1" $testRules

$validation = @'
param()

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root.Path

Write-Host ""
Write-Host "Testing AI Office automation engine..." -ForegroundColor Cyan
Write-Host ""

$errors = New-Object System.Collections.Generic.List[string]

$jsonFiles = @(
    ".\config\automation\automation-policy.json",
    ".\config\automation\automation-rule-schema.json",
    ".\config\automation\automation-trigger-schema.json",
    ".\workspace\automation\automation-index.json",
    ".\workspace\automation\state\engine-state.json",
    ".\workspace\templates\automation-rule-template.json"
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
    ".\scripts\automation\AIOfficeAutomation.Common.ps1",
    ".\scripts\automation\New-AIOfficeAutomationRule.ps1",
    ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1",
    ".\scripts\automation\Queue-AIOfficeAutomationEvent.ps1",
    ".\scripts\automation\Set-AIOfficeAutomationRuleState.ps1",
    ".\scripts\automation\Enable-AIOfficeAutomationRule.ps1",
    ".\scripts\automation\Disable-AIOfficeAutomationRule.ps1",
    ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1",
    ".\scripts\automation\Process-AIOfficeAutomationQueue.ps1",
    ".\scripts\automation\Archive-AIOfficeAutomationEvents.ps1",
    ".\scripts\automation\Test-AIOfficeAutomationRules.ps1",
    ".\scripts\automation\Test-AIOfficeAutomation.ps1"
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

$testRuleId = "AUT-VALIDATION-WRITE-LOG"
$testRulePath = Join-Path ".\workspace\automation\rules" ($testRuleId + ".json")

try {
    if (Test-Path -LiteralPath $testRulePath -PathType Leaf) {
        Remove-Item -LiteralPath $testRulePath -Force
    }

    $actions = @(
        [ordered]@{
            type = "write_log"
            message = "Package 13 validation rule executed."
        }
    ) | ConvertTo-Json -Depth 10 -Compress

    & ".\scripts\automation\New-AIOfficeAutomationRule.ps1" `
        -Name "Package 13 validation rule" `
        -Description "Temporary rule used by the validation suite." `
        -TriggerType "manual" `
        -ActionsJson $actions `
        -Priority 1 `
        -RuleId $testRuleId |
        Out-Null

    Write-Host "[RULE OK    ] Validation rule created." -ForegroundColor Green
}
catch {
    Write-Host "[RULE ERR   ] Rule creation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Rule creation failed: " + $_.Exception.Message)
}

try {
    $event = & ".\scripts\automation\Queue-AIOfficeAutomationEvent.ps1" `
        -TriggerType "manual" `
        -Source "Package13Validation" `
        -PayloadJson '{"validation":true}'

    if ($null -eq $event -or
        [string]::IsNullOrWhiteSpace([string]$event.event_id)) {
        throw "Queued event did not contain an event_id."
    }

    Write-Host (
        "[QUEUE OK   ] " +
        [string]$event.event_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[QUEUE ERR  ] Event queueing failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Event queueing failed: " + $_.Exception.Message)
}

try {
    & ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1" |
        Out-Null

    $logs = @(
        Get-ChildItem `
            -LiteralPath ".\workspace\automation\execution-log" `
            -Filter "RUN-*.json" `
            -File `
            -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
    )

    if ($logs.Count -eq 0) {
        throw "No execution log was generated."
    }

    $latest = Get-Content -LiteralPath $logs[0].FullName -Raw |
        ConvertFrom-Json

    if ([string]$latest.rule_id -ne $testRuleId) {
        throw "Latest execution log does not belong to the validation rule."
    }

    if (-not [bool]$latest.success) {
        throw "Validation automation execution did not succeed."
    }

    Write-Host (
        "[ENGINE OK  ] " +
        [string]$latest.run_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[ENGINE ERR ] Automation execution failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Automation execution failed: " + $_.Exception.Message)
}

try {
    $index = & ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1"

    if ($null -eq $index -or [int]$index.rule_count -lt 1) {
        throw "Automation index did not contain the validation rule."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$index.rule_count +
        " rule(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] Automation index failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Automation index failed: " + $_.Exception.Message)
}

try {
    & ".\scripts\automation\Disable-AIOfficeAutomationRule.ps1" `
        -RuleId $testRuleId |
        Out-Null

    $disabledRule = Get-Content -LiteralPath $testRulePath -Raw |
        ConvertFrom-Json

    if ([bool]$disabledRule.enabled) {
        throw "Rule was not disabled."
    }

    & ".\scripts\automation\Enable-AIOfficeAutomationRule.ps1" `
        -RuleId $testRuleId |
        Out-Null

    $enabledRule = Get-Content -LiteralPath $testRulePath -Raw |
        ConvertFrom-Json

    if (-not [bool]$enabledRule.enabled) {
        throw "Rule was not enabled."
    }

    Write-Host "[STATE OK   ] Rule enable/disable passed." -ForegroundColor Green
}
catch {
    Write-Host "[STATE ERR  ] Rule state test failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Rule state test failed: " + $_.Exception.Message)
}

if (Test-Path -LiteralPath $testRulePath -PathType Leaf) {
    Remove-Item -LiteralPath $testRulePath -Force
}

& ".\scripts\automation\Update-AIOfficeAutomationIndex.ps1" |
    Out-Null

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $errors.Count.ToString() +
        " automation engine error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All automation engine checks passed." -ForegroundColor Green
'@

New-SafeFile ".\scripts\automation\Test-AIOfficeAutomation.ps1" $validation

$guide = @'
# AI Office Package 13 — Automation Engine

Package 13 adds an event-driven automation engine to AI Office.

## Capabilities

- Rule-based triggers and actions
- Queued automation events
- Conditions
- Priority-ordered rule execution
- Execution logs
- Dry-run mode
- Duplicate suppression
- Maximum-depth loop protection
- Rule enable/disable controls
- Event archiving
- Dashboard and report actions
- PowerShell component execution
- Downstream event queueing

## Create a rule

```powershell
$actions = @(
    @{
        type = "write_log"
        message = "Workflow approval automation executed."
    }
) | ConvertTo-Json -Depth 10 -Compress

powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\New-AIOfficeAutomationRule.ps1" `
    -Name "Approved workflow handler" `
    -TriggerType "workflow_approved" `
    -ActionsJson $actions
```

## Queue an event

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Queue-AIOfficeAutomationEvent.ps1" `
    -TriggerType "workflow_approved" `
    -Source "workflow-engine" `
    -PayloadJson '{"workflow_id":"WF-1001","status":"approved"}'
```

## Process the queue

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1"
```

Dry-run mode:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Invoke-AIOfficeAutomationEngine.ps1" `
    -DryRun
```

## Disable or enable a rule

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Disable-AIOfficeAutomationRule.ps1" `
    -RuleId "AUT-EXAMPLE"
```

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Enable-AIOfficeAutomationRule.ps1" `
    -RuleId "AUT-EXAMPLE"
```

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\automation\Test-AIOfficeAutomation.ps1"
```

Expected result:

```text
All automation engine checks passed.
```

## Scheduling

Windows Task Scheduler can call:

```text
scripts\automation\Invoke-AIOfficeAutomationEngine.ps1
```

on a recurring schedule. Package 15 will connect scheduling, executive routines, reporting, and startup behavior into the final operating system.
'@

New-SafeFile ".\docs\Automation-Engine-Guide.md" $guide

Write-Host ""
Write-Host "Validating Package 13 JSON files..." -ForegroundColor Cyan

$validationFiles = @(
    ".\config\automation\automation-policy.json",
    ".\config\automation\automation-rule-schema.json",
    ".\config\automation\automation-trigger-schema.json",
    ".\workspace\automation\automation-index.json",
    ".\workspace\automation\state\engine-state.json",
    ".\workspace\templates\automation-rule-template.json"
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
            "Package 13 JSON validation failed for " +
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
            "Installers\AI-Office-Package-13-Install.ps1"

        $sourceFull = [System.IO.Path]::GetFullPath($source)
        $destinationFull = [System.IO.Path]::GetFullPath($destination)

        if ($sourceFull -ne $destinationFull) {
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
Write-Host "AI Office Package 13 installation completed." -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host ""
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\automation\Test-AIOfficeAutomation.ps1"'
Write-Host ""
