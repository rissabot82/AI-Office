param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeIdentity.Common.ps1")

$Root = Get-AIOfficeIdentityRoot
Set-Location $Root

$Identity = Get-AIOfficeIdentity
$Capabilities = Get-AIOfficeIdentityCapabilities
$Version = Read-AIOfficeIdentityJson `
    -Path ".\config\identity\version.json"

if ($null -eq $Identity -or
    $null -eq $Capabilities -or
    $null -eq $Version) {
    throw "Identity export could not load required configuration."
}

$Record = [ordered]@{
    exported_at = (Get-Date).ToString("o")
    identity = $Identity
    capabilities = $Capabilities
    release = $Version
}

$FileName = (
    "identity-export-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss") +
    ".json"
)

$Path = Join-Path ".\workspace\identity\exports" $FileName

Write-AIOfficeIdentityJson -Value $Record -Path $Path

$Index = Read-AIOfficeIdentityJson `
    -Path ".\workspace\identity\identity-index.json"

if ($null -eq $Index) {
    & ".\scripts\identity\Update-AIOfficeIdentityIndex.ps1" |
        Out-Null

    $Index = Read-AIOfficeIdentityJson `
        -Path ".\workspace\identity\identity-index.json"
}

$Index.latest_export = $Path
$Index.updated_at = (Get-Date).ToString("o")

Write-AIOfficeIdentityJson `
    -Value $Index `
    -Path ".\workspace\identity\identity-index.json"

Write-Host "Identity export created: $Path" -ForegroundColor Green
return $Path
