param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.5 Part B Extraction and Reasoning..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\knowledge-graph\reasoning-policy.json",
    ".\config\knowledge-graph\inference-schema.json",
    ".\config\knowledge-graph\contradiction-schema.json",
    ".\config\knowledge-graph\decision-score-schema.json",
    ".\workspace\templates\knowledge-graph-inference-template.json",
    ".\workspace\templates\knowledge-graph-contradiction-template.json",
    ".\workspace\templates\knowledge-graph-decision-score-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1",
    ".\scripts\knowledge-graph\Resolve-AIOfficeKnowledgeEntity.ps1",
    ".\scripts\knowledge-graph\Import-AIOfficeMemoryToKnowledgeGraph.ps1",
    ".\scripts\knowledge-graph\Get-AIOfficeKnowledgeNeighborhood.ps1",
    ".\scripts\knowledge-graph\Find-AIOfficeKnowledgeContradictions.ps1",
    ".\scripts\knowledge-graph\Rank-AIOfficeKnowledgeContext.ps1",
    ".\scripts\knowledge-graph\New-AIOfficeKnowledgeInference.ps1",
    ".\scripts\knowledge-graph\Score-AIOfficeKnowledgeDecision.ps1",
    ".\scripts\knowledge-graph\Test-AIOfficeKnowledgeReasoning.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$CreatedEntityIds = New-Object System.Collections.Generic.List[string]
$CreatedRelationshipIds = New-Object System.Collections.Generic.List[string]
$CreatedInferenceIds = New-Object System.Collections.Generic.List[string]
$CreatedDecisionIds = New-Object System.Collections.Generic.List[string]

try {
    $A = & ".\scripts\knowledge-graph\Resolve-AIOfficeKnowledgeEntity.ps1" `
        -Name "Certification Dealership B" `
        -EntityType "dealership" `
        -Scope "business" `
        -Confidence 0.95 `
        -SourceType "certification" `
        -SourceRef "v1.5-part-b"

    $B = & ".\scripts\knowledge-graph\Resolve-AIOfficeKnowledgeEntity.ps1" `
        -Name "Certification Platform B" `
        -EntityType "platform" `
        -Scope "business" `
        -Confidence 0.95 `
        -SourceType "certification" `
        -SourceRef "v1.5-part-b"

    $CreatedEntityIds.Add([string]$A.entity_id)
    $CreatedEntityIds.Add([string]$B.entity_id)

    $ResolvedAgain = & ".\scripts\knowledge-graph\Resolve-AIOfficeKnowledgeEntity.ps1" `
        -Name "Certification Dealership B" `
        -EntityType "dealership" `
        -Scope "business"

    if ([string]$ResolvedAgain.entity_id -ne [string]$A.entity_id) {
        throw "Entity resolution did not deduplicate by normalized name."
    }

    Write-Host "[RESOLVE OK] Entity deduplication passed." -ForegroundColor Green

    $Relationship = & ".\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphRelationship.ps1" `
        -RelationshipType "uses" `
        -FromEntityId ([string]$A.entity_id) `
        -ToEntityId ([string]$B.entity_id) `
        -Confidence 0.95 `
        -SourceType "certification" `
        -SourceRef "v1.5-part-b"

    $CreatedRelationshipIds.Add([string]$Relationship.relationship_id)

    $Neighborhood = & ".\scripts\knowledge-graph\Get-AIOfficeKnowledgeNeighborhood.ps1" `
        -EntityId ([string]$A.entity_id) `
        -Depth 2

    if ([int]$Neighborhood.entity_count -lt 2) {
        throw "Graph traversal did not include connected certification entities."
    }

    Write-Host "[TRAVERSE OK] $($Neighborhood.entity_count) connected entities" `
        -ForegroundColor Green

    $Ranked = @(
        & ".\scripts\knowledge-graph\Rank-AIOfficeKnowledgeContext.ps1" `
            -Query "Certification"
    )

    if ($Ranked.Count -lt 2) {
        throw "Context ranking did not return certification entities."
    }

    Write-Host "[RANK OK] $($Ranked.Count) ranked entities" -ForegroundColor Green

    $Inference = & ".\scripts\knowledge-graph\New-AIOfficeKnowledgeInference.ps1" `
        -InferenceType "relationship" `
        -Summary "Certification Dealership B uses Certification Platform B." `
        -Confidence 0.95 `
        -EvidenceJson ('["' + [string]$Relationship.relationship_id + '"]')

    $CreatedInferenceIds.Add([string]$Inference.inference_id)

    Write-Host "[INFERENCE OK] $($Inference.inference_id)" -ForegroundColor Green

    $Decision = & ".\scripts\knowledge-graph\Score-AIOfficeKnowledgeDecision.ps1" `
        -Title "Certification Decision" `
        -FactorsJson '[{"name":"impact","score":90,"weight":2},{"name":"effort","score":70,"weight":1}]'

    $CreatedDecisionIds.Add([string]$Decision.decision_score_id)

    if ([double]$Decision.score -ne 83.33) {
        throw "Decision score calculation was incorrect."
    }

    Write-Host "[DECISION OK] score=$($Decision.score)" -ForegroundColor Green

    $Contradictions = @(
        & ".\scripts\knowledge-graph\Find-AIOfficeKnowledgeContradictions.ps1"
    )

    Write-Host "[CONTRADICTION OK] Scan completed." -ForegroundColor Green
}
catch {
    Write-Host "[REASONING ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Id in $CreatedRelationshipIds) {
    $Path = ".\workspace\knowledge-graph\relationships\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Id in $CreatedEntityIds) {
    $Path = ".\workspace\knowledge-graph\entities\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Id in $CreatedInferenceIds) {
    $Path = ".\workspace\knowledge-graph\inference\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Id in $CreatedDecisionIds) {
    $Path = ".\workspace\knowledge-graph\decision-scores\$Id.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\knowledge-graph\contradictions" `
    -Filter "KGC-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        try {
            $Record = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json

            if (
                [string]$Record.entity_id -in @($CreatedEntityIds) -or
                [string]$Record.comparison_entity_id -in @($CreatedEntityIds)
            ) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
        catch {
        }
    }

& ".\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Extraction and Reasoning error(s) found." `
        -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.5 Part B Extraction and Reasoning checks passed." `
    -ForegroundColor Green
