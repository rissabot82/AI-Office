param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

$IndexPath = "E:\AI\AI-Office\workspace\knowledge-graph\indexes\graph-index.json"

$Index = & "E:\AI\AI-Office\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1"

$Entities = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\entities" `
        -Filter "KGE-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 12 |
    ForEach-Object {
        try {
            Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        }
        catch {
        }
    }
)

$Relationships = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\relationships" `
        -Filter "KGR-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 12 |
    ForEach-Object {
        try {
            Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        }
        catch {
        }
    }
)

$Inferences = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\inference" `
        -Filter "KGI-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 8 |
    ForEach-Object {
        try {
            Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        }
        catch {
        }
    }
)

$Contradictions = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\contradictions" `
        -Filter "KGC-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 8 |
    ForEach-Object {
        try {
            Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        }
        catch {
        }
    }
)

$DecisionScores = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\decision-scores" `
        -Filter "KGD-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 8 |
    ForEach-Object {
        try {
            Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        }
        catch {
        }
    }
)

$Snapshot = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    status = [string]$Index.status
    entity_count = [int]$Index.entity_count
    relationship_count = [int]$Index.relationship_count
    inference_count = @($Inferences).Count
    contradiction_count = @($Contradictions).Count
    decision_score_count = @($DecisionScores).Count
    entity_type_counts = $Index.entity_type_counts
    relationship_type_counts = $Index.relationship_type_counts
    scope_counts = $Index.scope_counts
    recent_entities = @(
        $Entities |
        ForEach-Object {
            [ordered]@{
                entity_id = [string]$_.entity_id
                name = [string]$_.name
                entity_type = [string]$_.entity_type
                scope = [string]$_.scope
                confidence = [double]$_.confidence
                updated_at = [string]$_.updated_at
            }
        }
    )
    recent_relationships = @(
        $Relationships |
        ForEach-Object {
            [ordered]@{
                relationship_id = [string]$_.relationship_id
                relationship_type = [string]$_.relationship_type
                from_entity_id = [string]$_.from_entity_id
                from_entity_name = [string]$_.from_entity_name
                to_entity_id = [string]$_.to_entity_id
                to_entity_name = [string]$_.to_entity_name
                confidence = [double]$_.confidence
                updated_at = [string]$_.updated_at
            }
        }
    )
    recent_inferences = @(
        $Inferences |
        ForEach-Object {
            [ordered]@{
                inference_id = [string]$_.inference_id
                inference_type = [string]$_.inference_type
                summary = [string]$_.summary
                confidence = [double]$_.confidence
                created_at = [string]$_.created_at
            }
        }
    )
    contradictions = @(
        $Contradictions |
        ForEach-Object {
            [ordered]@{
                contradiction_id = [string]$_.contradiction_id
                entity_id = [string]$_.entity_id
                field = [string]$_.field
                status = [string]$_.status
                created_at = [string]$_.created_at
            }
        }
    )
    decision_scores = @(
        $DecisionScores |
        ForEach-Object {
            [ordered]@{
                decision_score_id = [string]$_.decision_score_id
                title = [string]$_.title
                score = [double]$_.score
                created_at = [string]$_.created_at
            }
        }
    )
}

$OutputPath = "E:\AI\AI-Office\dashboard\public\knowledge-graph-status.json"

$Snapshot |
    ConvertTo-Json -Depth 80 |
    Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host "Knowledge Graph dashboard snapshot updated." -ForegroundColor Green

return [pscustomobject]$Snapshot
