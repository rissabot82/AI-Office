param(
    [Parameter(Mandatory=$true)][string]$RelationshipType,
    [Parameter(Mandatory=$true)][string]$FromEntityId,
    [Parameter(Mandatory=$true)][string]$ToEntityId,
    [double]$Confidence = 0.75,
    [string]$AttributesJson = "{}",
    [string]$SourceType = "manual",
    [string]$SourceRef = "",
    [string]$SourceDetail = ""
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

$Policy = Get-AIOfficeKnowledgeGraphPolicy

if (@($Policy.relationship_types) -notcontains $RelationshipType) {
    throw "Unsupported Knowledge Graph relationship type: $RelationshipType"
}

if ($FromEntityId -eq $ToEntityId) {
    throw "A relationship cannot connect an entity to itself."
}

$FromEntity = Get-AIOfficeKnowledgeGraphEntity -EntityId $FromEntityId
$ToEntity = Get-AIOfficeKnowledgeGraphEntity -EntityId $ToEntityId

try {
    $Attributes = $AttributesJson | ConvertFrom-Json
}
catch {
    throw "AttributesJson is invalid JSON."
}

$RelationshipId = New-AIOfficeKnowledgeGraphRelationshipId
$Now = (Get-Date).ToString("o")

$Relationship = [ordered]@{
    relationship_id = $RelationshipId
    relationship_type = $RelationshipType
    from_entity_id = $FromEntityId
    from_entity_name = [string]$FromEntity.name
    to_entity_id = $ToEntityId
    to_entity_name = [string]$ToEntity.name
    confidence = $Confidence
    attributes = $Attributes
    provenance = [ordered]@{
        source_type = $SourceType
        source_ref = $SourceRef
        source_detail = $SourceDetail
        captured_at = $Now
    }
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeKnowledgeGraphJson -Value $Relationship -Path "E:\AI\AI-Office\workspace\knowledge-graph\relationships\$RelationshipId.json"
& "E:\AI\AI-Office\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1" | Out-Null

Write-Host "Knowledge Graph relationship created: $RelationshipId" -ForegroundColor Green
return [pscustomobject]$Relationship
