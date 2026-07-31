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
