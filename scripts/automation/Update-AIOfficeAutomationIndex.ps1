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
