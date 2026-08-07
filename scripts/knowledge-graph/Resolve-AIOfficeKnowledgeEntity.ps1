param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$EntityType,
    [string]$Scope = "business",
    [double]$Confidence = 0.72,
    [string]$SourceType = "extraction",
    [string]$SourceRef = "",
    [string]$SourceDetail = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1"

$Existing = Find-AIOfficeKnowledgeEntityByName `
    -Name $Name `
    -EntityType $EntityType

if ($null -ne $Existing) {
    Write-Host "Knowledge Graph entity resolved: $($Existing.entity_id) | $($Existing.name)" `
        -ForegroundColor Yellow

    return $Existing
}

return & "E:\AI\AI-Office\scripts\knowledge-graph\New-AIOfficeKnowledgeGraphEntity.ps1" `
    -EntityType $EntityType `
    -Name $Name `
    -Scope $Scope `
    -Confidence $Confidence `
    -SourceType $SourceType `
    -SourceRef $SourceRef `
    -SourceDetail $SourceDetail
