param([Parameter(Mandatory=$true)][string]$RuleId)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "Set-AIOfficeAutomationRuleState.ps1") `
    -RuleId $RuleId `
    -Enabled $true
