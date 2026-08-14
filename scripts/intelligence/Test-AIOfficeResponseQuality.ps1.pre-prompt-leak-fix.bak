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
    if ($Text.StartsWith([string]$Prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        $Reasons.Add("Response contains an exposed role prefix: $Prefix")
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
