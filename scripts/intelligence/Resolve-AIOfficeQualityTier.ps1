param(
    [Parameter(Mandatory=$true)][string]$TaskFamily,
    [string]$ExplicitTier = ""
)

$ErrorActionPreference = "Stop"

if (-not [string]::IsNullOrWhiteSpace($ExplicitTier)) {
    $Normalized = $ExplicitTier.Trim().ToLowerInvariant()

    if (@("fast","standard","high") -contains $Normalized) {
        return $Normalized
    }

    throw "Unknown quality tier: $ExplicitTier"
}

switch ($TaskFamily) {
    "conversation"   { return "fast" }
    "classification" { return "fast" }
    "reasoning"      { return "standard" }
    "creative"       { return "standard" }
    "drafting"       { return "standard" }
    "analysis"       { return "standard" }
    "summarization"  { return "standard" }
    "coding"         { return "high" }
    default          { return "standard" }
}
