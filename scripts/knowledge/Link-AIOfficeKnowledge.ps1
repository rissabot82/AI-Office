param(
    [Parameter(Mandatory = $true)]
    [string]$KnowledgeId,

    [Parameter(Mandatory = $true)]
    [string]$RelatedKnowledgeId,

    [string]$Relationship = "related-to",
    [string]$LinkedBy = "Clarissa",
    [switch]$OneWay
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

function Add-KnowledgeLink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceId,

        [Parameter(Mandatory = $true)]
        [string]$TargetId,

        [Parameter(Mandatory = $true)]
        [string]$LinkRelationship,

        [Parameter(Mandatory = $true)]
        [string]$Actor
    )

    $sourcePath = Join-Path `
        (Join-Path ".\workspace\knowledge\items" $SourceId) `
        "knowledge.json"

    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Knowledge item not found: $SourceId"
    }

    $targetPath = Join-Path `
        (Join-Path ".\workspace\knowledge\items" $TargetId) `
        "knowledge.json"

    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
        throw "Related knowledge item not found: $TargetId"
    }

    $item = Get-Content -LiteralPath $sourcePath -Raw | ConvertFrom-Json
    $existing = @(
        $item.links | Where-Object {
            $_.knowledge_id -eq $TargetId -and
            $_.relationship -eq $LinkRelationship
        }
    )

    if ($existing.Count -eq 0) {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

        $item.links = @($item.links) + [PSCustomObject]@{
            knowledge_id = $TargetId
            relationship = $LinkRelationship
        }

        $item.updated_at = $timestamp
        $item.version = [int]$item.version + 1
        $item.history = @($item.history) + [PSCustomObject]@{
            timestamp = $timestamp
            action = "knowledge-linked"
            actor = $Actor
            details = "Linked to $TargetId using relationship $LinkRelationship."
        }

        $item |
            ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath $sourcePath -Encoding UTF8
    }
}

Add-KnowledgeLink `
    -SourceId $KnowledgeId `
    -TargetId $RelatedKnowledgeId `
    -LinkRelationship $Relationship `
    -Actor $LinkedBy

if (-not $OneWay) {
    Add-KnowledgeLink `
        -SourceId $RelatedKnowledgeId `
        -TargetId $KnowledgeId `
        -LinkRelationship $Relationship `
        -Actor $LinkedBy
}

& ".\scripts\knowledge\Update-AIOfficeKnowledgeIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Knowledge items linked successfully." -ForegroundColor Green
Write-Host "Source:       $KnowledgeId"
Write-Host "Related item: $RelatedKnowledgeId"
Write-Host "Relationship: $Relationship"
Write-Host "Two-way:      $(-not $OneWay.IsPresent)"
