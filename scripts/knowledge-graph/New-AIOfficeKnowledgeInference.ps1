param(
    [Parameter(Mandatory=$true)][string]$InferenceType,
    [Parameter(Mandatory=$true)][string]$Summary,
    [double]$Confidence = 0.75,
    [string]$EvidenceJson = "[]"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

try {
    $Evidence = @($EvidenceJson | ConvertFrom-Json)
}
catch {
    throw "EvidenceJson is invalid JSON."
}

$InferenceId = New-AIOfficeKnowledgeInferenceId

$Inference = [ordered]@{
    inference_id = $InferenceId
    inference_type = $InferenceType
    summary = $Summary
    confidence = $Confidence
    evidence = $Evidence
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeKnowledgeGraphJson `
    -Value $Inference `
    -Path "E:\AI\AI-Office\workspace\knowledge-graph\inference\$InferenceId.json"

Write-Host "Knowledge Graph inference created: $InferenceId" -ForegroundColor Green

return [pscustomobject]$Inference
