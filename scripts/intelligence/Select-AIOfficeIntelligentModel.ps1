param(
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$TaskFamily = "",
    [string]$QualityTier = "",
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

$Policy = & "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeModelSelectionPolicy.ps1"
$Baseline = & "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeModelBenchmarkBaseline.ps1"

$ResolvedFamily = & "E:\AI\AI-Office\scripts\intelligence\Resolve-AIOfficeTaskFamily.ps1" `
    -Content $Content `
    -ExplicitFamily $TaskFamily

$ResolvedTier = & "E:\AI\AI-Office\scripts\intelligence\Resolve-AIOfficeQualityTier.ps1" `
    -TaskFamily $ResolvedFamily `
    -ExplicitTier $QualityTier

$Inventory = & "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeModelInventory.ps1"

$AvailableModels = @(
    $Inventory.models |
    Where-Object { [bool]$_.available } |
    ForEach-Object { [string]$_.model }
)

if ($AvailableModels.Count -eq 0) {
    throw "No available Ollama models were discovered."
}

$Preferences = @($Policy.task_preferences.$ResolvedFamily)

if ($Preferences.Count -eq 0) {
    $Preferences = @($Policy.selection.fallback_model_order)
}

$Threshold = [double]$Policy.quality_thresholds.$ResolvedTier
$Candidates = New-Object System.Collections.Generic.List[object]

$BestQualified = $null
$BestQualifiedScore = -1.0

$BestAvailable = $null
$BestAvailableScore = -1.0

$PreferenceRank = 0

foreach ($Model in $Preferences) {

    if ($AvailableModels -notcontains [string]$Model) {
        $PreferenceRank++
        continue
    }

    $Score = 0.0

    $ModelProperty = @(
        $Baseline.models.PSObject.Properties |
        Where-Object { $_.Name -eq [string]$Model }
    ) | Select-Object -First 1

    if ($null -ne $ModelProperty) {

        $FamilyProperty = @(
            $ModelProperty.Value.family_scores.PSObject.Properties |
            Where-Object { $_.Name -eq [string]$ResolvedFamily }
        ) | Select-Object -First 1

        if ($null -ne $FamilyProperty) {
            $Score = [double]$FamilyProperty.Value
        }
        else {
            $Score = [double]$ModelProperty.Value.average
        }
    }

    $Candidate = [pscustomobject]@{
        model = [string]$Model
        family_score = [math]::Round($Score,4)
        meets_threshold = ($Score -ge $Threshold)
        preference_rank = $PreferenceRank
    }

    $Candidates.Add($Candidate)

    # Strictly greater only.
    # Equal scores keep the earlier model from the preference list.
    if ($Score -gt $BestAvailableScore) {
        $BestAvailable = $Candidate
        $BestAvailableScore = $Score
    }

    if (
        $Candidate.meets_threshold -and
        $Score -gt $BestQualifiedScore
    ) {
        $BestQualified = $Candidate
        $BestQualifiedScore = $Score
    }

    $PreferenceRank++
}

if ($Candidates.Count -eq 0) {
    throw "No candidate models are available for task family $ResolvedFamily."
}

$RequiresEscalation = $false
$SelectionReason = ""

if ($null -ne $BestQualified) {
    $Selected = $BestQualified
    $SelectionReason = "Selected highest benchmarked family score meeting the $ResolvedTier threshold; preference order breaks ties."
}
else {
    $Selected = $BestAvailable
    $RequiresEscalation = $true
    $SelectionReason = "No local model met the $ResolvedTier threshold; selected best available local fallback and marked for escalation."
}

if ($ResolvedFamily -eq "coding") {
    $RequiresEscalation = $true
    $SelectionReason = "Current coding benchmark is below target for all local models; preferred coding model selected locally but escalation remains recommended."
}

$SelectionId = "INTSEL-" +
    (Get-Date -Format "yyyyMMdd-HHmmss") +
    "-" +
    ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()

$Result = [ordered]@{
    selection_id = $SelectionId
    task_family = $ResolvedFamily
    quality_tier = $ResolvedTier
    selected_model = [string]$Selected.model
    provider = "ollama"
    selected_family_score = [double]$Selected.family_score
    quality_threshold = $Threshold
    selection_reason = $SelectionReason
    candidate_models = $Candidates.ToArray()
    requires_escalation = $RequiresEscalation
    production_integration_enabled = [bool]$Policy.selection.production_integration_enabled
    created_at = (Get-Date).ToString("o")
}

if ($Persist) {
    $Directory = "E:\AI\AI-Office\workspace\intelligence\model-selections"
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null

    $Result |
        ConvertTo-Json -Depth 50 |
        Set-Content `
            -LiteralPath (Join-Path $Directory ($SelectionId + ".json")) `
            -Encoding UTF8
}

return [pscustomobject]$Result
