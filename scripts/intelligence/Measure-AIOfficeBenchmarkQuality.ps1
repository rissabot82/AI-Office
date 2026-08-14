param(
    [Parameter(Mandatory=$true)]$BenchmarkResult,
    [Parameter(Mandatory=$true)]$BenchmarkCase,
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\quality-scoring-policy.json" `
    -Raw |
    ConvertFrom-Json

$Requirements = @($BenchmarkCase.requirements)
$PassedRequirements = 0
$Notes = New-Object System.Collections.Generic.List[string]

foreach ($Requirement in $Requirements) {
    $Passed = & "E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeBenchmarkRequirement.ps1" `
        -Requirement ([string]$Requirement) `
        -Response ([string]$BenchmarkResult.response)

    if ($Passed) {
        $PassedRequirements++
    }
    else {
        $Notes.Add("Requirement failed: $Requirement")
    }
}

$RequirementScore = if ($Requirements.Count -eq 0) {
    1.0
}
else {
    [double]$PassedRequirements / [double]$Requirements.Count
}

$Response = [string]$BenchmarkResult.response
$LengthScore = [math]::Min(1.0, [double]$Response.Length / 300.0)
$ForbiddenPenalty = 0.0

foreach ($Phrase in @($Policy.heuristics.forbidden_phrases)) {
    if ($Response.ToLowerInvariant().Contains(([string]$Phrase).ToLowerInvariant())) {
        $ForbiddenPenalty += 0.2
    }
}

$QualityScore = [math]::Max(0.0, [math]::Min(1.0, $LengthScore - $ForbiddenPenalty))

$Tier = [string]$BenchmarkCase.quality_tier
$Reference = [double]$Policy.scoring.latency_reference_ms.$Tier
$Elapsed = [double]$BenchmarkResult.elapsed_ms

$LatencyScore = if ($Elapsed -le 0) {
    0.0
}
else {
    [math]::Min(1.0, $Reference / $Elapsed)
}

$Weights = $Policy.scoring.weights

$Overall = (
    ([double]$Weights.requirement_coverage * $RequirementScore) +
    ([double]$Weights.response_quality * $QualityScore) +
    ([double]$Weights.latency_efficiency * $LatencyScore)
)

$Threshold = [double]$Policy.scoring.pass_thresholds.$Tier
$PassedOverall = ($Overall -ge $Threshold)

$EvaluationId = "INTEVAL-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()

$Evaluation = [ordered]@{
    evaluation_id = $EvaluationId
    benchmark_id = [string]$BenchmarkResult.benchmark_id
    model = [string]$BenchmarkResult.model
    case_id = [string]$BenchmarkCase.id
    family = [string]$BenchmarkCase.family
    quality_tier = $Tier
    requirement_score = [math]::Round($RequirementScore,4)
    quality_score = [math]::Round($QualityScore,4)
    latency_score = [math]::Round($LatencyScore,4)
    overall_score = [math]::Round($Overall,4)
    passed = $PassedOverall
    notes = $Notes.ToArray()
    created_at = (Get-Date).ToString("o")
}

if ($Persist) {
    $Directory = "E:\AI\AI-Office\workspace\intelligence\evaluations"
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null

    $Evaluation |
        ConvertTo-Json -Depth 50 |
        Set-Content `
            -LiteralPath (Join-Path $Directory ($EvaluationId + ".json")) `
            -Encoding UTF8
}

return [pscustomobject]$Evaluation
