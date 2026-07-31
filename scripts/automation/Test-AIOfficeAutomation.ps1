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
