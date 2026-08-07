param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

$Ideas = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\ideas" `
        -Filter "BIZIDEA-*.json"
)

$Evaluations = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\evaluations" `
        -Filter "BIZEVAL-*.json"
)

$Validations = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\validation-results" `
        -Filter "BIZVR-*.json"
)

$Markets = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\market-analysis" `
        -Filter "BIZMKT-*.json"
)

$Budgets = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\budget-analysis" `
        -Filter "BIZBUD-*.json"
)

$Portfolios = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\portfolio" `
        -Filter "BIZPORT-*.json" |
    Sort-Object created_at -Descending
)

$IdeaRows = New-Object System.Collections.Generic.List[object]

foreach ($Idea in $Ideas) {
    $IdeaId = [string]$Idea.idea_id

    $Eval = @(
        $Evaluations |
        Where-Object { [string]$_.idea_id -eq $IdeaId } |
        Sort-Object created_at -Descending
    ) | Select-Object -First 1

    $Validation = @(
        $Validations |
        Where-Object { [string]$_.idea_id -eq $IdeaId } |
        Sort-Object created_at -Descending
    ) | Select-Object -First 1

    $Budget = @(
        $Budgets |
        Where-Object { [string]$_.idea_id -eq $IdeaId } |
        Sort-Object created_at -Descending
    ) | Select-Object -First 1

    $IdeaRows.Add([pscustomobject]@{
        idea_id = $IdeaId
        name = [string]$Idea.name
        opportunity_type = [string]$Idea.opportunity_type
        status = [string]$Idea.status
        target_customer = [string]$Idea.target_customer
        estimated_startup_cost = [double]$Idea.estimated_startup_cost
        estimated_monthly_revenue = [double]$Idea.estimated_monthly_revenue
        validation_score = if ($null -ne $Validation) { [double]$Validation.score } else { 0.0 }
        validation_status = if ($null -ne $Validation) { [string]$Validation.status } else { "not_tested" }
        venture_score = if ($null -ne $Eval) { [double]$Eval.composite_score } else { 0.0 }
        recommendation = if ($null -ne $Eval) { [string]$Eval.recommendation } else { "unevaluated" }
        expected_monthly_profit = if ($null -ne $Budget) { [double]$Budget.expected_monthly_profit } else { 0.0 }
        months_to_break_even = if ($null -ne $Budget) { [double]$Budget.months_to_break_even } else { 0.0 }
    })
}

$RecommendationCounts = [ordered]@{
    go = @($Evaluations | Where-Object { [string]$_.recommendation -eq "go" }).Count
    conditional = @($Evaluations | Where-Object { [string]$_.recommendation -eq "conditional" }).Count
    no_go = @($Evaluations | Where-Object { [string]$_.recommendation -eq "no_go" }).Count
}

$LatestPortfolio = if ($Portfolios.Count -gt 0) { $Portfolios[0] } else { $null }

$Snapshot = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    version = "1.8.0"
    release_name = "Business Incubator"
    summary = [ordered]@{
        ideas = $Ideas.Count
        market_analyses = $Markets.Count
        validation_results = $Validations.Count
        venture_evaluations = $Evaluations.Count
        budget_analyses = $Budgets.Count
        recommendations = $RecommendationCounts
    }
    ideas = @(
        $IdeaRows |
        Sort-Object `
            @{ Expression = { [double]$_.venture_score }; Descending = $true },
            @{ Expression = { [string]$_.name }; Descending = $false }
    )
    portfolio = if ($null -ne $LatestPortfolio) { @($LatestPortfolio.rankings) } else { @() }
}

$Destination = "E:\AI\AI-Office\dashboard\runtime\business-incubator-snapshot.json"
$Parent = Split-Path -Parent $Destination

if (-not (Test-Path -LiteralPath $Parent -PathType Container)) {
    New-Item -ItemType Directory -Path $Parent -Force | Out-Null
}

$Snapshot | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $Destination -Encoding UTF8

Write-Host "Business Incubator dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
