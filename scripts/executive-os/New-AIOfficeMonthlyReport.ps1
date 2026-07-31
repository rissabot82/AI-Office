param()

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "New-AIOfficeExecutiveBriefing.ps1") `
    -Type "monthly"
