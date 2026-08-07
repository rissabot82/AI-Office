param()

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

$Ideas = Get-AIOfficeBusinessCollection `
    -Directory "E:\AI\AI-Office\workspace\business-incubator\ideas" `
    -Filter "BIZIDEA-*.json"

$Scores = Get-AIOfficeBusinessCollection `
    -Directory "E:\AI\AI-Office\workspace\business-incubator\scores" `
    -Filter "BIZSCORE-*.json"

$Research = Get-AIOfficeBusinessCollection `
    -Directory "E:\AI\AI-Office\workspace\business-incubator\research" `
    -Filter "BIZRES-*.json"

$Validation = Get-AIOfficeBusinessCollection `
    -Directory "E:\AI\AI-Office\workspace\business-incubator\validation" `
    -Filter "BIZVAL-*.json"

$LaunchPlans = Get-AIOfficeBusinessCollection `
    -Directory "E:\AI\AI-Office\workspace\business-incubator\launch-plans" `
    -Filter "BIZLAUNCH-*.json"

$StatusCounts = [ordered]@{}
$TypeCounts = [ordered]@{}

foreach ($Idea in $Ideas) {
    $Status = [string]$Idea.status
    $Type = [string]$Idea.opportunity_type

    if (-not $StatusCounts.Contains($Status)) { $StatusCounts[$Status] = 0 }
    if (-not $TypeCounts.Contains($Type)) { $TypeCounts[$Type] = 0 }

    $StatusCounts[$Status]++
    $TypeCounts[$Type]++
}

$ScoreTotal = 0.0
foreach ($Score in $Scores) {
    $ScoreTotal += [double]$Score.total_score
}

$AverageScore = if (@($Scores).Count -gt 0) {
    $ScoreTotal / @($Scores).Count
}
else {
    0.0
}

$ActiveStatuses = @("captured","researching","validating","approved","launched")

$Index = [ordered]@{
    version = "1.8.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    idea_count = @($Ideas).Count
    active_idea_count = @(
        $Ideas |
        Where-Object { @($ActiveStatuses) -contains [string]$_.status }
    ).Count
    research_record_count = @($Research).Count
    validation_experiment_count = @($Validation).Count
    launch_plan_count = @($LaunchPlans).Count
    average_opportunity_score = [math]::Round($AverageScore,2)
    status_counts = $StatusCounts
    type_counts = $TypeCounts
}

Write-AIOfficeBusinessJson `
    -Value $Index `
    -Path "E:\AI\AI-Office\workspace\business-incubator\indexes\incubator-index.json"

Write-Host "Business Incubator index updated: $($Index.idea_count) ideas | $($Index.research_record_count) research | $($Index.validation_experiment_count) experiments" -ForegroundColor Green
return [pscustomobject]$Index
