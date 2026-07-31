param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeIdentity.Common.ps1")

$Root = Get-AIOfficeIdentityRoot
Set-Location $Root

$Identity = Get-AIOfficeIdentity
$Capabilities = Get-AIOfficeIdentityCapabilities

if ($null -eq $Identity) {
    throw "Identity configuration could not be loaded."
}

if ($null -eq $Capabilities) {
    throw "Capability configuration could not be loaded."
}

$GroupCount = @(
    $Capabilities.capability_groups.PSObject.Properties
).Count

$RestrictedCount = @(
    $Capabilities.restricted_capabilities
).Count

$Existing = Read-AIOfficeIdentityJson `
    -Path ".\workspace\identity\identity-index.json"

$LatestExport = ""

if ($null -ne $Existing -and
    $null -ne $Existing.PSObject.Properties["latest_export"]) {
    $LatestExport = [string]$Existing.latest_export
}

$Index = [ordered]@{
    schema_version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    office_id = [string]$Identity.office_id
    office_name = [string]$Identity.name
    office_version = [string]$Identity.version
    codename = [string]$Identity.codename
    status = [string]$Identity.status
    execution_engine = [string]$Identity.execution_engine
    capability_group_count = [int]$GroupCount
    restricted_capability_count = [int]$RestrictedCount
    identity_valid = $true
    latest_export = $LatestExport
}

Write-AIOfficeIdentityJson `
    -Value $Index `
    -Path ".\workspace\identity\identity-index.json"

Write-Host (
    "Identity index updated: " +
    [string]$Index.office_name +
    " v" +
    [string]$Index.office_version
) -ForegroundColor Green

return [pscustomobject]$Index
