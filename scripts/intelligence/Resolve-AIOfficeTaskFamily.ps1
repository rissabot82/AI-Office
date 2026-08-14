param(
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$ExplicitFamily = ""
)

$ErrorActionPreference = "Stop"

$Allowed = @(
    "conversation",
    "reasoning",
    "creative",
    "drafting",
    "analysis",
    "classification",
    "coding",
    "summarization"
)

if (-not [string]::IsNullOrWhiteSpace($ExplicitFamily)) {
    $Normalized = $ExplicitFamily.Trim().ToLowerInvariant()

    if ($Allowed -contains $Normalized) {
        return $Normalized
    }

    throw "Unknown task family: $ExplicitFamily"
}

$Text = $Content.ToLowerInvariant()

if ($Text -match '\b(code|powershell|python|javascript|html|css|debug|script|regex|function|api)\b') {
    return "coding"
}

if ($Text -match '\b(summarize|summary|recap|condense|tl;dr)\b') {
    return "summarization"
}

if ($Text -match '\b(analyze|analysis|compare|comparison|strategy|strategic|evaluate|review performance|cost per|roi|roas|cpl)\b') {
    return "analysis"
}

if ($Text -match '\b(write|draft|rewrite|email|headline|copy|description|blurb|response|reply)\b') {
    if ($Text -match '\b(poem|creative|campaign idea|campaign concept|brainstorm|slogan|tagline)\b') {
        return "creative"
    }

    return "drafting"
}

if ($Text -match '\b(poem|story|creative|brainstorm|idea|ideas|concept|concepts|joke|slogan|tagline)\b') {
    return "creative"
}

if ($Text -match '\b(classify|classification|categorize|category|route|routing)\b') {
    return "classification"
}

if ($Text -match '\b(calculate|math|times|multiply|divide|reason|why|solve|logic|deduce)\b') {
    return "reasoning"
}

return "conversation"
