param(
    [switch]$DryRun,
    [int]$MaxEvents = 0
)

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "Invoke-AIOfficeAutomationEngine.ps1") `
    -DryRun:$DryRun `
    -MaxEvents $MaxEvents
