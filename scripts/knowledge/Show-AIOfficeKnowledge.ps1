param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [switch]$MetadataOnly,
    [switch]$ShowHistory
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
$contentPath = Join-Path $itemFolder ([string]$item.content_file)

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AI Office Knowledge Item" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Knowledge ID:  $($item.knowledge_id)"
Write-Host "Title:         $($item.title)"
Write-Host "Summary:       $($item.summary)"
Write-Host "Type:          $($item.type)"
Write-Host "Category:      $($item.category)"
Write-Host "Status:        $($item.status)"
Write-Host "Visibility:    $($item.visibility)"
Write-Host "Owner:         $($item.owner_agent)"
Write-Host "Version:       $($item.version)"
Write-Host "Created:       $($item.created_at)"
Write-Host "Updated:       $($item.updated_at)"
Write-Host "Tags:          $(@($item.tags) -join ', ')"
Write-Host "Links:         $(@($item.links).Count)"
Write-Host "Sources:       $(@($item.sources).Count)"

if (-not $MetadataOnly) {
    Write-Host ""
    Write-Host "Content" -ForegroundColor Cyan
    Write-Host "-------" -ForegroundColor Cyan

    if (Test-Path -LiteralPath $contentPath -PathType Leaf) {
        Get-Content -LiteralPath $contentPath
    }
    else {
        Write-Host "Content file is missing." -ForegroundColor Red
    }
}

if ($ShowHistory) {
    Write-Host ""
    Write-Host "History" -ForegroundColor Cyan
    Write-Host "-------" -ForegroundColor Cyan

    foreach ($entry in @($item.history)) {
        Write-Host (
            "{0} | {1} | {2} | {3}" -f
            $entry.timestamp,
            $entry.action,
            $entry.actor,
            $entry.details
        )
    }
}
