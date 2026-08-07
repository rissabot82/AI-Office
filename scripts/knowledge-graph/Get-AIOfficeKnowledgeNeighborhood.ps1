param(
    [Parameter(Mandatory=$true)][string]$EntityId,
    [int]$Depth = 2
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

$Policy = Get-AIOfficeKnowledgeReasoningPolicy
$MaxDepth = [int]$Policy.reasoning.maximum_traversal_depth

if ($Depth -lt 1) {
    $Depth = 1
}

if ($Depth -gt $MaxDepth) {
    $Depth = $MaxDepth
}

$RootEntity = Get-AIOfficeKnowledgeGraphEntity -EntityId $EntityId
$Relationships = @(Get-AIOfficeKnowledgeAllRelationships)

$Visited = @{}
$Queue = New-Object System.Collections.Queue
$Queue.Enqueue([pscustomobject]@{ entity_id=$EntityId; depth=0 })
$Visited[$EntityId] = 0

while ($Queue.Count -gt 0) {
    $Current = $Queue.Dequeue()

    if ([int]$Current.depth -ge $Depth) {
        continue
    }

    foreach ($Relationship in $Relationships) {
        $NeighborId = ""

        if ([string]$Relationship.from_entity_id -eq [string]$Current.entity_id) {
            $NeighborId = [string]$Relationship.to_entity_id
        }
        elseif ([string]$Relationship.to_entity_id -eq [string]$Current.entity_id) {
            $NeighborId = [string]$Relationship.from_entity_id
        }

        if (-not $NeighborId) {
            continue
        }

        if (-not $Visited.ContainsKey($NeighborId)) {
            $Visited[$NeighborId] = ([int]$Current.depth + 1)
            $Queue.Enqueue([pscustomobject]@{
                entity_id = $NeighborId
                depth = ([int]$Current.depth + 1)
            })
        }
    }
}

$Entities = New-Object System.Collections.Generic.List[object]

foreach ($Id in $Visited.Keys) {
    try {
        $Entity = Get-AIOfficeKnowledgeGraphEntity -EntityId ([string]$Id)

        $Entities.Add([pscustomobject]@{
            entity_id = [string]$Entity.entity_id
            name = [string]$Entity.name
            entity_type = [string]$Entity.entity_type
            scope = [string]$Entity.scope
            confidence = [double]$Entity.confidence
            depth = [int]$Visited[$Id]
        })
    }
    catch {
    }
}

return [pscustomobject]@{
    root_entity_id = $EntityId
    root_entity_name = [string]$RootEntity.name
    depth = $Depth
    entity_count = $Entities.Count
    entities = @($Entities | Sort-Object depth, name)
}
