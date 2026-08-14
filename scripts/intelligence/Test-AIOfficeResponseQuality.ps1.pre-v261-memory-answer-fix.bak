param(
    [Parameter(Mandatory=$true)][string]$Response
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\response-quality-policy.json" `
    -Raw | ConvertFrom-Json

$Reasons = New-Object System.Collections.Generic.List[string]
$Text = $Response.Trim()

if ([string]::IsNullOrWhiteSpace($Text)) {
    $Reasons.Add("Response is empty.")
}

if ($Text.Length -lt [int]$Policy.quality_control.minimum_response_characters) {
    $Reasons.Add("Response is too short to be useful.")
}

foreach ($Prefix in @($Policy.quality_control.reject_role_prefixes)) {
    $EscapedPrefix = [regex]::Escape([string]$Prefix)

    if ($Text -match "(?im)^\s*$EscapedPrefix") {
        $Reasons.Add("Response contains an exposed role prefix: $Prefix")
    }
}

$InternalMarkers = @(
    "BEGIN CONVERSATION PROMPT",
    "END CONVERSATION PROMPT",
    "RESPONSE QUALITY RULES:",
    "IMPORTANT RETRY INSTRUCTION:"
)

foreach ($Marker in $InternalMarkers) {
    if ($Text.IndexOf($Marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $Reasons.Add("Response contains exposed internal prompt material: $Marker")
    }
}

foreach ($Pattern in @($Policy.quality_control.reject_non_answer_patterns)) {
    if ($Text.IndexOf([string]$Pattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $Reasons.Add("Response contains rejected non-answer language: $Pattern")
    }
}

return [pscustomobject]@{
    passed = ($Reasons.Count -eq 0)
    reasons = $Reasons.ToArray()
    response_length = $Text.Length
}

