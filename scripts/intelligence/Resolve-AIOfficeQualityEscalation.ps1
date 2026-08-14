param(
    [Parameter(Mandatory=$true)][string]$Content,
    [Parameter(Mandatory=$true)][string]$TaskFamily,
    [Parameter(Mandatory=$true)][string]$SelectedModel,
    [Parameter(Mandatory=$true)][double]$ModelScore,
    [string]$Complexity = "medium"
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\quality-escalation-policy.json" `
    -Raw | ConvertFrom-Json

$ThresholdProperty = $Policy.family_thresholds.PSObject.Properties |
    Where-Object { $_.Name -eq $TaskFamily } |
    Select-Object -First 1

$Threshold = if ($null -ne $ThresholdProperty) {
    [double]$ThresholdProperty.Value
} else {
    0.90
}

$Reasons = New-Object System.Collections.Generic.List[string]

if ($ModelScore -lt $Threshold) {
    $Reasons.Add(("Local benchmark score {0:N4} is below the {1:N4} quality threshold for {2}." -f $ModelScore,$Threshold,$TaskFamily))
}

$ComplexityProperty = $Policy.complexity_escalation.PSObject.Properties |
    Where-Object { $_.Name -eq $Complexity } |
    Select-Object -First 1

if ($null -ne $ComplexityProperty -and [bool]$ComplexityProperty.Value) {
    $Reasons.Add("Request complexity is high.")
}

$KeywordHits = @()
foreach ($Keyword in @($Policy.quality_sensitive_keywords)) {
    if ($Content.IndexOf([string]$Keyword,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $KeywordHits += [string]$Keyword
    }
}

# Keywords are supporting evidence, not sufficient by themselves.
$QualitySensitive = $KeywordHits.Count -gt 0
$RequiresEscalation = $Reasons.Count -gt 0

return [pscustomobject]@{
    requires_escalation = $RequiresEscalation
    advisory_only = -not [bool]$Policy.automatic_external_escalation_enabled
    task_family = $TaskFamily
    selected_model = $SelectedModel
    local_score = $ModelScore
    quality_threshold = $Threshold
    complexity = $Complexity
    quality_sensitive = $QualitySensitive
    keyword_hits = $KeywordHits
    reasons = $Reasons.ToArray()
    external_provider_configured = [bool]$Policy.external_provider.configured
    resolved_at = (Get-Date).ToString("o")
}
