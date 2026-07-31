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
