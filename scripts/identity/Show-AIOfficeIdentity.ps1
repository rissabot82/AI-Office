param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeIdentity.Common.ps1")

$Root = Get-AIOfficeIdentityRoot
Set-Location $Root

$Index = & ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1"
$Identity = Get-AIOfficeIdentity
$Capabilities = Get-AIOfficeIdentityCapabilities

Write-Host ""
Write-Host "AI OFFICE IDENTITY" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host ("Office ID       : " + [string]$Identity.office_id)
Write-Host ("Name            : " + [string]$Identity.formal_name)
Write-Host ("Version         : " + [string]$Identity.version)
Write-Host ("Codename        : " + [string]$Identity.codename)
Write-Host ("Status          : " + [string]$Identity.status)
Write-Host ("Executive Role  : " + [string]$Identity.executive_role)
Write-Host ("Execution Engine: " + [string]$Identity.execution_engine)
Write-Host ("Repository      : " + [string]$Identity.repository)
Write-Host ""
Write-Host "MISSION" -ForegroundColor Yellow
Write-Host ([string]$Identity.mission)
Write-Host ""
Write-Host "CAPABILITY GROUPS" -ForegroundColor Yellow

foreach ($Property in $Capabilities.capability_groups.PSObject.Properties) {
    Write-Host (
        "- " +
        [string]$Property.Name +
        ": " +
        @($Property.Value).Count.ToString()
    )
}

Write-Host ""
return $Index
