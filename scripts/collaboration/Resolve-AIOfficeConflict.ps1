param(
    [Parameter(Mandatory=$true)][string]$ConflictId,
    [Parameter(Mandatory=$true)][string]$ResolvedByAgent,
    [Parameter(Mandatory=$true)][string]$Resolution
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$path = Join-Path `
    ".\workspace\collaboration\conflicts" `
    ($ConflictId + ".json")

$record = Read-AIOfficeCollaborationJson -Path $path

if ($null -eq $record) {
    throw "Conflict not found: $ConflictId"
}

$resolvedAt = (Get-Date).ToString("o")

$record.status = "resolved"
$record.resolution = $Resolution
$record.updated_at = $resolvedAt

if ($null -ne $record.PSObject.Properties["resolved_by_agent"]) {
    $record.resolved_by_agent = $ResolvedByAgent
}
else {
    $record | Add-Member `
        -MemberType NoteProperty `
        -Name "resolved_by_agent" `
        -Value $ResolvedByAgent
}

if ($null -ne $record.PSObject.Properties["resolved_at"]) {
    $record.resolved_at = $resolvedAt
}
else {
    $record | Add-Member `
        -MemberType NoteProperty `
        -Name "resolved_at" `
        -Value $resolvedAt
}

Write-AIOfficeCollaborationJson `
    -Value $record `
    -Path $path

& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" |
    Out-Null

Write-Host "Conflict resolved: $ConflictId" -ForegroundColor Green
