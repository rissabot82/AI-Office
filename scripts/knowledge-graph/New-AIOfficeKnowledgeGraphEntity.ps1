param(
    [Parameter(Mandatory=$true)][string]$EntityType,
    [Parameter(Mandatory=$true)][string]$Name,
    [string]$Scope = "business",
    [double]$Confidence = 0.75,
    [string]$AliasesJson = "[]",
    [string]$AttributesJson = "{}",
    [string]$SourceType = "manual",
    [string]$SourceRef = "",
    [string]$SourceDetail = ""
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

$Policy = Get-AIOfficeKnowledgeGraphPolicy

if (@($Policy.entity_types) -notcontains $EntityType) {
    throw "Unsupported Knowledge Graph entity type: $EntityType"
}

if ($Confidence -lt 0 -or $Confidence -gt 1) {
    throw "Confidence must be between 0 and 1."
}

try {
    $Aliases = @($AliasesJson | ConvertFrom-Json)
    $Attributes = $AttributesJson | ConvertFrom-Json
}
catch {
    throw "AliasesJson or AttributesJson is invalid JSON."
}

$EntityId = New-AIOfficeKnowledgeGraphEntityId
$Now = (Get-Date).ToString("o")

$Entity = [ordered]@{
    entity_id = $EntityId
    entity_type = $EntityType
    name = $Name
    aliases = $Aliases
    scope = $Scope
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

Write-AIOfficeKnowledgeGraphJson -Value $Entity -Path "E:\AI\AI-Office\workspace\knowledge-graph\entities\$EntityId.json"
& "E:\AI\AI-Office\scripts\knowledge-graph\Update-AIOfficeKnowledgeGraphIndex.ps1" | Out-Null

Write-Host "Knowledge Graph entity created: $EntityId | $Name" -ForegroundColor Green
return [pscustomobject]$Entity
