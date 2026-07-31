param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [string]$ArchivedBy = "Clarissa",
    [string]$Reason = "Knowledge item archived."
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$itemFolder = Join-Path ".\workspace\knowledge\items" $KnowledgeId
$itemPath = Join-Path $itemFolder "knowledge.json"

if (-not (Test-Path -LiteralPath $itemPath -PathType Leaf)) {
    throw "Knowledge item not found: $KnowledgeId"
}

$item = Get-Content -LiteralPath $itemPath -Raw | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$item.status = "archived"
$item.updated_at = $timestamp
$item.version = [int]$item.version + 1
$item.history = @($item.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "knowledge-archived"
    actor = $ArchivedBy
    details = $Reason
}

$item |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $itemPath -Encoding UTF8

$archiveRoot = Join-Path ".\workspace\knowledge\archive" $KnowledgeId

if (-not (Test-Path -LiteralPath $archiveRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
}

Copy-Item -Path (Join-Path $itemFolder "*") -Destination $archiveRoot -Recurse -Force

& ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Knowledge item archived successfully." -ForegroundColor Green
Write-Host "Knowledge ID: $KnowledgeId"
Write-Host "Archive copy: $archiveRoot"
