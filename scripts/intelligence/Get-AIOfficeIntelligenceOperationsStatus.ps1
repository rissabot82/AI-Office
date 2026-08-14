param()

$ErrorActionPreference = "Stop"

$SelectionDir = "E:\AI\AI-Office\workspace\intelligence\model-selections"
$TurnDir = "E:\AI\AI-Office\workspace\conversational-office\turns"

$Selections = @(
    Get-ChildItem -LiteralPath $SelectionDir -Filter "INTSEL-*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 100 |
    ForEach-Object {
        try { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json } catch {}
    }
)

$Turns = @(
    Get-ChildItem -LiteralPath $TurnDir -Filter "*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 100 |
    ForEach-Object {
        try { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json } catch {}
    }
)

$IntelligentTurns = @(
    $Turns | Where-Object {
        $null -ne $_.routing -and
        -not [string]::IsNullOrWhiteSpace([string]$_.routing.intelligent_task_family)
    }
)

$FallbackTurns = @(
    $IntelligentTurns | Where-Object {
        [bool]$_.routing.intelligence_fallback_used
    }
)

$EscalationSelections = @(
    $Selections | Where-Object {
        [bool]$_.requires_escalation
    }
)

$ByModel = [ordered]@{}
foreach ($Selection in $Selections) {
    $Model = [string]$Selection.selected_model
    if ([string]::IsNullOrWhiteSpace($Model)) { continue }
    if (-not $ByModel.Contains($Model)) { $ByModel[$Model] = 0 }
    $ByModel[$Model]++
}

$ByFamily = [ordered]@{}
foreach ($Selection in $Selections) {
    $Family = [string]$Selection.task_family
    if ([string]::IsNullOrWhiteSpace($Family)) { continue }
    if (-not $ByFamily.Contains($Family)) { $ByFamily[$Family] = 0 }
    $ByFamily[$Family]++
}

return [pscustomobject]@{
    tracked_selections = $Selections.Count
    intelligent_turns = $IntelligentTurns.Count
    fallback_turns = $FallbackTurns.Count
    escalation_recommendations = $EscalationSelections.Count
    model_usage = [pscustomobject]$ByModel
    family_usage = [pscustomobject]$ByFamily
    latest_selection = if ($Selections.Count -gt 0) { [string]$Selections[0].selection_id } else { "" }
    checked_at = (Get-Date).ToString("o")
}
