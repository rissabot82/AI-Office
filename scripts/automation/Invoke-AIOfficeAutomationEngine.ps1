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
