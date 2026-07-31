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
