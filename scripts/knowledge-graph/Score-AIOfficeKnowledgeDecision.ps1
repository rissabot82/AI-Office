param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$FactorsJson
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeReasoning.Common.ps1"
. "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

try {
    $ParsedFactors = ConvertFrom-Json -InputObject $FactorsJson

    $Factors = @(
        $ParsedFactors |
            ForEach-Object { $_ }
    )
}
catch {
    throw "FactorsJson is invalid JSON."
}

if ($Factors.Count -lt 1) {
    throw "At least one decision factor is required."
}

$WeightedTotal = 0.0
$WeightTotal = 0.0
$NormalizedFactors = New-Object System.Collections.Generic.List[object]

foreach ($Factor in $Factors) {
    $Name = [string]$Factor.name
    $Score = [double]$Factor.score
    $Weight = [double]$Factor.weight

    if ($Score -lt 0 -or $Score -gt 100) {
        throw "Decision factor scores must be between 0 and 100."
    }

    if ($Weight -lt 0) {
        throw "Decision factor weights cannot be negative."
    }

    $WeightedTotal += ($Score * $Weight)
    $WeightTotal += $Weight

    $NormalizedFactors.Add([pscustomobject]@{
        name = $Name
        score = $Score
        weight = $Weight
    })
}

if ($WeightTotal -le 0) {
    throw "Total factor weight must be greater than zero."
}

$FinalScore = [math]::Round(($WeightedTotal / $WeightTotal), 2)
$DecisionScoreId = New-AIOfficeKnowledgeDecisionScoreId

$Record = [ordered]@{
    decision_score_id = $DecisionScoreId
    title = $Title
    score = $FinalScore
    factors = @($NormalizedFactors | ForEach-Object { $_ })
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeKnowledgeGraphJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\knowledge-graph\decision-scores\$DecisionScoreId.json"

Write-Host "Knowledge Graph decision score created: $DecisionScoreId | $FinalScore" `
    -ForegroundColor Green

return [pscustomobject]$Record

