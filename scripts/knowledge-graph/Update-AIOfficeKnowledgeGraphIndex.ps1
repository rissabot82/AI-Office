param()

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

$EntityFiles = @(Get-ChildItem -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\entities" -Filter "KGE-*.json" -File -ErrorAction SilentlyContinue)
$RelationshipFiles = @(Get-ChildItem -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\relationships" -Filter "KGR-*.json" -File -ErrorAction SilentlyContinue)

$Entities = @(
    foreach ($File in $EntityFiles) {
        $Record = Read-AIOfficeKnowledgeGraphJson -Path $File.FullName
        if ($null -ne $Record) { $Record }
    }
)

$Relationships = @(
    foreach ($File in $RelationshipFiles) {
        $Record = Read-AIOfficeKnowledgeGraphJson -Path $File.FullName
        if ($null -ne $Record) { $Record }
    }
)

$EntityTypeCounts = [ordered]@{}
$RelationshipTypeCounts = [ordered]@{}
$ScopeCounts = [ordered]@{}

foreach ($Entity in $Entities) {
    $Type = [string]$Entity.entity_type
    $Scope = [string]$Entity.scope

    if (-not $EntityTypeCounts.Contains($Type)) { $EntityTypeCounts[$Type] = 0 }
    if (-not $ScopeCounts.Contains($Scope)) { $ScopeCounts[$Scope] = 0 }

    $EntityTypeCounts[$Type]++
    $ScopeCounts[$Scope]++
}

foreach ($Relationship in $Relationships) {
    $Type = [string]$Relationship.relationship_type
    if (-not $RelationshipTypeCounts.Contains($Type)) { $RelationshipTypeCounts[$Type] = 0 }
    $RelationshipTypeCounts[$Type]++
}

$LatestEntity = @($Entities | Sort-Object updated_at -Descending | Select-Object -First 1)
$LatestRelationship = @($Relationships | Sort-Object updated_at -Descending | Select-Object -First 1)

$Index = [ordered]@{
    version = "1.5.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    entity_count = $Entities.Count
    relationship_count = $Relationships.Count
    entity_type_counts = $EntityTypeCounts
    relationship_type_counts = $RelationshipTypeCounts
    scope_counts = $ScopeCounts
    latest_entity_id = if ($LatestEntity.Count -gt 0) { [string]$LatestEntity[0].entity_id } else { "" }
    latest_relationship_id = if ($LatestRelationship.Count -gt 0) { [string]$LatestRelationship[0].relationship_id } else { "" }
}

Write-AIOfficeKnowledgeGraphJson -Value $Index -Path "E:\AI\AI-Office\workspace\knowledge-graph\indexes\graph-index.json"

Write-Host "Knowledge Graph index updated: $($Entities.Count) entities, $($Relationships.Count) relationships" -ForegroundColor Green
return [pscustomobject]$Index
