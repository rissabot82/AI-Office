param(
    [string]$Query = "",
    [string]$EntityType = "",
    [string]$Scope = "",
    [int]$Limit = 50
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-ChildItem -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\entities" -Filter "KGE-*.json" -File -ErrorAction SilentlyContinue)) {
    $Entity = Read-AIOfficeKnowledgeGraphJson -Path $File.FullName
    if ($null -eq $Entity) { continue }
    if ($EntityType -and [string]$Entity.entity_type -ne $EntityType) { continue }
    if ($Scope -and [string]$Entity.scope -ne $Scope) { continue }

    $Haystack = [string]$Entity.name + " " + (@($Entity.aliases) -join " ") + " " + ($Entity.attributes | ConvertTo-Json -Depth 20 -Compress)

    if ($Query -and $Haystack -notmatch [regex]::Escape($Query)) { continue }
    $Results.Add($Entity)
}

return @($Results | Sort-Object confidence -Descending | Select-Object -First $Limit)
