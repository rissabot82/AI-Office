param(
    [Parameter(Mandatory=$true)][string]$DelegationId,
    [Parameter(Mandatory=$true)][string]$Status
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if (@($policy.allowed_delegation_statuses) -notcontains $Status) {
    throw "Unsupported delegation status: $Status"
}

$path = Join-Path ".\workspace\collaboration\delegations" ($DelegationId + ".json")
$record = Read-AIOfficeCollaborationJson -Path $path

if ($null -eq $record) {
    throw "Delegation not found: $DelegationId"
}

$record.status = $Status
$record.updated_at = (Get-Date).ToString("o")

Write-AIOfficeCollaborationJson -Value $record -Path $path
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host (
    "Delegation " +
    $DelegationId +
    " updated to " +
    $Status +
    "."
) -ForegroundColor Green
