param()

$ErrorActionPreference = "Stop"

$Index = & "E:\AI\AI-Office\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE KNOWLEDGE GRAPH" -ForegroundColor Cyan
Write-Host ("=" * 64)
Write-Host ("Entities       : " + [string]$Index.entity_count)
Write-Host ("Relationships  : " + [string]$Index.relationship_count)
Write-Host ("Latest entity  : " + [string]$Index.latest_entity_id)
Write-Host ("Latest relation: " + [string]$Index.latest_relationship_id)
Write-Host ""

return $Index
