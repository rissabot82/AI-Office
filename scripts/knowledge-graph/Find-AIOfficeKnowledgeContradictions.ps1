param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

$Entities = @(Get-AIOfficeKnowledgeAllEntities)
$Contradictions = New-Object System.Collections.Generic.List[object]

$Groups = $Entities |
    Group-Object {
        (Normalize-AIOfficeKnowledgeName -Name ([string]$_.name)) +
        "|" +
        [string]$_.entity_type
    }

foreach ($Group in $Groups) {
    if ($Group.Count -lt 2) {
        continue
    }

    $Records = @($Group.Group)

    for ($i = 0; $i -lt $Records.Count; $i++) {
        for ($j = $i + 1; $j -lt $Records.Count; $j++) {
            $A = $Records[$i]
            $B = $Records[$j]

            $AJson = $A.attributes | ConvertTo-Json -Depth 20 -Compress
            $BJson = $B.attributes | ConvertTo-Json -Depth 20 -Compress

            if ($AJson -eq $BJson) {
                continue
            }

            $ContradictionId = New-AIOfficeKnowledgeContradictionId

            $Record = [ordered]@{
                contradiction_id = $ContradictionId
                entity_id = [string]$A.entity_id
                comparison_entity_id = [string]$B.entity_id
                field = "attributes"
                value_a = $AJson
                value_b = $BJson
                status = "open"
                created_at = (Get-Date).ToString("o")
            }

            Write-AIOfficeKnowledgeGraphJson `
                -Value $Record `
                -Path "E:\AI\AI-Office\workspace\knowledge-graph\contradictions\$ContradictionId.json"

            $Contradictions.Add([pscustomobject]$Record)
        }
    }
}

Write-Host "Knowledge Graph contradiction scan completed: $($Contradictions.Count) contradiction(s)." `
    -ForegroundColor Green

return @($Contradictions | ForEach-Object { $_ })
