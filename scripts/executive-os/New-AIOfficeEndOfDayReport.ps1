param()

$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "New-AIOfficeExecutiveBriefing.ps1") `
    -Type "end_of_day"
