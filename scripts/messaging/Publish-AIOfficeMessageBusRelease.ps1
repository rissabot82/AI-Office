param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$ManifestPath = ".\config\messaging\release-manifest.json"
$Manifest = Read-AIOfficeMessagingJson -Path $ManifestPath

if ($null -eq $Manifest) {
    throw "Message Bus release manifest could not be loaded."
}

$Manifest.release_status = "released"
$Manifest.released_at = (Get-Date).ToString("o")

Write-AIOfficeMessagingJson -Value $Manifest -Path $ManifestPath

$ReleaseRecord = [ordered]@{
    product = "AI Office"
    component = "Internal Message Bus"
    version = "1.1.2"
    released_at = (Get-Date).ToString("o")
    status = "released"
    next_milestone = "1.1.3 OpenClaw Bridge"
}

$Path = Join-Path `
    ".\workspace\messages\releases" `
    ("AI-Office-v1.1.2-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")

Write-AIOfficeMessagingJson -Value $ReleaseRecord -Path $Path

Write-Host "AI Office v1.1.2 release recorded." -ForegroundColor Green
return [pscustomobject]$ReleaseRecord
