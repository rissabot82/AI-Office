param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.5 Part A Knowledge Graph Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\knowledge-graph\graph-policy.json",
    ".\config\knowledge-graph\entity-schema.json",
    ".\config\knowledge-graph\relationship-schema.json",
    ".\config\knowledge-graph\provenance-schema.json",
    ".\config\knowledge-graph\graph-index-schema.json",
    ".\workspace\knowledge-graph\indexes\graph-index.json",
    ".\workspace\templates\knowledge-graph-entity-template.json",
    ".\workspace\templates\knowledge-graph-relationship-template.json"
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
    ".\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1",
    ".\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphEntity.ps1",
    ".\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphRelationship.ps1",
    ".\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1",
    ".\scripts\knowledge-graph\Search-AIOfficeKnowledgeGraph.ps1",
    ".\scripts\knowledge-graph\Show-AIOfficeKnowledgeGraphStatus.ps1",
    ".\scripts\knowledge-graph\Test-AIOfficeKnowledgeGraphArchitecture.ps1"
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

$EntityIds = New-Object System.Collections.Generic.List[string]
$RelationshipId = ""

try {
    $Dealership = & ".\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphEntity.ps1" `
        -EntityType "dealership" `
        -Name "Certification Dealership" `
        -Scope "business" `
        -Confidence 0.95 `
        -AttributesJson '{"purpose":"certification"}' `
        -SourceType "certification" `
        -SourceRef "v1.5-part-a"

    $Platform = & ".\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphEntity.ps1" `
        -EntityType "platform" `
        -Name "Certification Platform" `
        -Scope "business" `
        -Confidence 0.95 `
        -AttributesJson '{"purpose":"certification"}' `
        -SourceType "certification" `
        -SourceRef "v1.5-part-a"

    $EntityIds.Add([string]$Dealership.entity_id)
    $EntityIds.Add([string]$Platform.entity_id)

    $Relationship = & ".\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphRelationship.ps1" `
        -RelationshipType "uses" `
        -FromEntityId ([string]$Dealership.entity_id) `
        -ToEntityId ([string]$Platform.entity_id) `
        -Confidence 0.95 `
        -SourceType "certification" `
        -SourceRef "v1.5-part-a"

    $RelationshipId = [string]$Relationship.relationship_id

    $Search = @(& ".\scripts\knowledge-graph\Search-AIOfficeKnowledgeGraph.ps1" -Query "Certification")
    if ($Search.Count -lt 2) { throw "Knowledge Graph search did not return certification entities." }

    $Index = & ".\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1"
    if ([int]$Index.entity_count -lt 2 -or [int]$Index.relationship_count -lt 1) {
        throw "Knowledge Graph index did not contain certification records."
    }

    Write-Host "[GRAPH OK] $($Dealership.entity_id) -> uses -> $($Platform.entity_id)" -ForegroundColor Green
    Write-Host "[SEARCH OK] $($Search.Count) matching entities" -ForegroundColor Green
    Write-Host "[INDEX OK] $($Index.entity_count) entities | $($Index.relationship_count) relationships" -ForegroundColor Green
}
catch {
    Write-Host "[GRAPH ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($EntityId in $EntityIds) {
    $Path = ".\workspace\knowledge-graph\entities\$EntityId.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

if ($RelationshipId) {
    $Path = ".\workspace\knowledge-graph\relationships\$RelationshipId.json"
    if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force }
}

& ".\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Knowledge Graph architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.5 Part A Knowledge Graph Architecture checks passed." -ForegroundColor Green
