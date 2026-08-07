param()

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeVenturePlanning.Common.ps1"

$Ideas = @(
    Get-AIOfficeBusinessCollection `
        -Directory "E:\AI\AI-Office\workspace\business-incubator\ideas" `
        -Filter "BIZIDEA-*.json" |
    Where-Object {
        [string]$_.status -ne "rejected" -and
        [string]$_.status -ne "paused"
    }
)

$Rankings = New-Object System.Collections.Generic.List[object]

foreach ($Idea in $Ideas) {
    $Evaluations = @(
        Get-AIOfficeBusinessCollection `
            -Directory "E:\AI\AI-Office\workspace\business-incubator\evaluations" `
            -Filter "BIZEVAL-*.json" |
        Where-Object { [string]$_.idea_id -eq [string]$Idea.idea_id } |
        Sort-Object created_at -Descending
    )

    $Score = if ($Evaluations.Count -gt 0) {
        [double]$Evaluations[0].composite_score
    }
    else {
        0.0
    }

    $Rankings.Add([pscustomobject]@{
        idea_id = [string]$Idea.idea_id
        name = [string]$Idea.name
        opportunity_type = [string]$Idea.opportunity_type
        status = [string]$Idea.status
        score = [math]::Round($Score,2)
        recommendation = if ($Evaluations.Count -gt 0) { [string]$Evaluations[0].recommendation } else { "unevaluated" }
    })
}

$Ordered = @(
    $Rankings |
    Sort-Object `
        @{ Expression = { [double]$_.score }; Descending = $true },
        @{ Expression = { [string]$_.name }; Descending = $false }
)

$Position = 1
$Final = @(
    foreach ($Item in $Ordered) {
        [ordered]@{
            rank = $Position
            idea_id = [string]$Item.idea_id
            name = [string]$Item.name
            opportunity_type = [string]$Item.opportunity_type
            status = [string]$Item.status
            score = [double]$Item.score
            recommendation = [string]$Item.recommendation
        }
        $Position++
    }
)

$Id = New-AIOfficeVenturePlanningId -Prefix "BIZPORT"

$Record = [ordered]@{
    portfolio_id = $Id
    rankings = $Final
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\portfolio\$Id.json"

Write-Host "Venture portfolio prioritized: $Id | $(@($Final).Count) idea(s)" -ForegroundColor Green
return [pscustomobject]$Record

