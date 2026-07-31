param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeExecutiveOS.Common.ps1")

$root = Get-AIOfficeExecutiveOSRoot
Set-Location $root

$manifestPath = ".\workspace\executive-os\release-manifest.json"
$manifest = Read-AIOfficeExecutiveOSJson -Path $manifestPath

if ($null -eq $manifest) {
    throw "Release manifest could not be loaded."
}

$now = (Get-Date).ToString("o")
$manifest.installed_at = $now
$manifest.release_status = "released"

Write-AIOfficeExecutiveOSJson -Value $manifest -Path $manifestPath

$releaseRecord = [ordered]@{
    product = "AI Office"
    version = "1.0.0"
    release_name = "Executive Operating System"
    released_at = $now
    status = "released"
    validation_required = $true
}

$path = Join-Path `
    ".\workspace\executive-os\releases" `
    ("AI-Office-v1.0-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeExecutiveOSJson -Value $releaseRecord -Path $path

Write-Host "AI Office v1.0 release recorded." -ForegroundColor Green
return [pscustomobject]$releaseRecord

