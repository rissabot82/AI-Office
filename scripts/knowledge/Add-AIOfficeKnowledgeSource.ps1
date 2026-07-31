param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [string]$Notes = "",
    [string]$AddedBy = "Clarissa"
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$itemPath = Join-Path `
    (Join-Path ".\workspace\knowledge\items" $KnowledgeId) `
    "knowledge.json"

if (-not (Test-Path -LiteralPath $itemPath -PathType Leaf)) {
    throw "Knowledge item not found: $KnowledgeId"
}

$item = Get-Content -LiteralPath $itemPath -Raw | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$item.sources = @($item.sources) + [PSCustomObject]@{
    title = $Title
    location = $Location
    accessed_at = $timestamp
    notes = $Notes
}

$item.updated_at = $timestamp
$item.version = [int]$item.version + 1
$item.history = @($item.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "source-added"
    actor = $AddedBy
    details = "Source added: $Title"
}

$item |
    ConvertTo-Json -Depth 20 |
    Set-Content -LiteralPath $itemPath -Encoding UTF8

& ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Source added successfully." -ForegroundColor Green
Write-Host "Knowledge ID: $KnowledgeId"
Write-Host "Source title: $Title"
Write-Host "Location:     $Location"
