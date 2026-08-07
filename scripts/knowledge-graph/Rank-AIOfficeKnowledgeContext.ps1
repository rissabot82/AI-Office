param(
    [Parameter(Mandatory=$true)][string]$Query,
    [string]$Scope = "",
    [int]$Limit = 15
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1"

$Policy = Get-AIOfficeKnowledgeReasoningPolicy
$Entities = @(Get-AIOfficeKnowledgeAllEntities)
$Relationships = @(Get-AIOfficeKnowledgeAllRelationships)
$Now = Get-Date
$Scored = New-Object System.Collections.Generic.List[object]

foreach ($Entity in $Entities) {
    if ($Scope -and [string]$Entity.scope -ne $Scope) {
        continue
    }

    $Text = (
        [string]$Entity.name + " " +
        (@($Entity.aliases) -join " ") + " " +
        ($Entity.attributes | ConvertTo-Json -Depth 20 -Compress)
    )

    $QueryMatch = 0.0

    foreach ($Term in @($Query -split "\s+" | Where-Object { $_ })) {
        if ($Text -match [regex]::Escape($Term)) {
            $QueryMatch += 1.0
        }
    }

    if ($QueryMatch -eq 0) {
        continue
    }

    $ConfidenceScore = [double]$Entity.confidence

    $AgeDays = 365.0

    try {
        $Updated = [datetime]$Entity.updated_at
        $AgeDays = [math]::Max(0.0, ($Now - $Updated).TotalDays)
    }
    catch {
    }

    $RecencyScore = 1.0 / (1.0 + ($AgeDays / 30.0))

    $RelationshipCount = @(
        $Relationships |
            Where-Object {
                [string]$_.from_entity_id -eq [string]$Entity.entity_id -or
                [string]$_.to_entity_id -eq [string]$Entity.entity_id
            }
    ).Count

    $RelationshipScore = [math]::Min(1.0, ($RelationshipCount / 5.0))
    $ScopeScore = if ($Scope -and [string]$Entity.scope -eq $Scope) { 1.0 } else { 0.75 }
    $QueryScore = [math]::Min(1.0, ($QueryMatch / 3.0))

    $FinalScore = (
        ($ConfidenceScore * [double]$Policy.scoring.confidence_weight) +
        ($RecencyScore * [double]$Policy.scoring.recency_weight) +
        ($RelationshipScore * [double]$Policy.scoring.relationship_weight) +
        ($ScopeScore * [double]$Policy.scoring.scope_weight)
    ) * $QueryScore

    $Scored.Add([pscustomobject]@{
        entity_id = [string]$Entity.entity_id
        name = [string]$Entity.name
        entity_type = [string]$Entity.entity_type
        scope = [string]$Entity.scope
        confidence = [double]$Entity.confidence
        relationship_count = $RelationshipCount
        score = [math]::Round($FinalScore, 4)
    })
}

return @(
    $Scored |
        Sort-Object score -Descending |
        Select-Object -First $Limit
)
