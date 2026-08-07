param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v1.8 Part A Business Incubator Architecture..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\business-incubator\incubator-policy.json",
    ".\config\business-incubator\idea-schema.json",
    ".\config\business-incubator\opportunity-score-schema.json",
    ".\config\business-incubator\research-record-schema.json",
    ".\config\business-incubator\validation-experiment-schema.json",
    ".\config\business-incubator\launch-plan-schema.json",
    ".\workspace\business-incubator\indexes\incubator-index.json",
    ".\workspace\templates\business-idea-template.json",
    ".\workspace\templates\business-opportunity-score-template.json",
    ".\workspace\templates\business-research-template.json",
    ".\workspace\templates\business-validation-template.json",
    ".\workspace\templates\business-launch-plan-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: $File")
    }
}

$Scripts = @(
    ".\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1",
    ".\scripts\business-incubator\New-AIOfficeBusinessIdea.ps1",
    ".\scripts\business-incubator\New-AIOfficeOpportunityScore.ps1",
    ".\scripts\business-incubator\New-AIOfficeBusinessResearch.ps1",
    ".\scripts\business-incubator\New-AIOfficeValidationExperiment.ps1",
    ".\scripts\business-incubator\New-AIOfficeLaunchPlan.ps1",
    ".\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1",
    ".\scripts\business-incubator\Show-AIOfficeBusinessIncubatorStatus.ps1",
    ".\scripts\business-incubator\Test-AIOfficeBusinessIncubatorArchitecture.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: $Script")
    }
}

$Created = New-Object System.Collections.Generic.List[object]

try {
    $Idea = & ".\scripts\business-incubator\New-AIOfficeBusinessIdea.ps1" `
        -Name "Certification AI Reporting Service" `
        -OpportunityType "service" `
        -Summary "Certification idea for automated reporting." `
        -TargetCustomer "Small businesses" `
        -Problem "Manual reporting takes too long." `
        -Solution "Automated reporting workflow." `
        -RevenueModel "Monthly subscription" `
        -EstimatedStartupCost 500 `
        -EstimatedMonthlyRevenue 2500

    $Created.Add([pscustomobject]@{ type="idea"; id=[string]$Idea.idea_id })

    $Score = & ".\scripts\business-incubator\New-AIOfficeOpportunityScore.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -DimensionsJson '[{"name":"market_demand","score":85,"weight":2},{"name":"profit_potential","score":90,"weight":2},{"name":"startup_cost","score":80,"weight":1},{"name":"automation_potential","score":95,"weight":2}]'

    $Created.Add([pscustomobject]@{ type="score"; id=[string]$Score.score_id })

    if ([double]$Score.total_score -lt 80) {
        throw "Opportunity scoring returned an unexpectedly low score."
    }

    Write-Host "[SCORE OK] $($Score.score_id) | $($Score.total_score)" -ForegroundColor Green

    $Research = & ".\scripts\business-incubator\New-AIOfficeBusinessResearch.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -ResearchType "market_research" `
        -Summary "Certification research record." `
        -SourcesJson '["https://example.com/research"]' `
        -FindingsJson '{"demand":"positive"}'

    $Created.Add([pscustomobject]@{ type="research"; id=[string]$Research.research_id })
    Write-Host "[RESEARCH OK] $($Research.research_id)" -ForegroundColor Green

    $Experiment = & ".\scripts\business-incubator\New-AIOfficeValidationExperiment.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -Method "landing_page" `
        -Hypothesis "Target customers will request more information." `
        -SuccessMetric "At least 10 qualified leads."

    $Created.Add([pscustomobject]@{ type="validation"; id=[string]$Experiment.experiment_id })
    Write-Host "[VALIDATION OK] $($Experiment.experiment_id)" -ForegroundColor Green

    $Launch = & ".\scripts\business-incubator\New-AIOfficeLaunchPlan.ps1" `
        -IdeaId ([string]$Idea.idea_id) `
        -Name "Certification MVP Launch" `
        -Budget 1000 `
        -MilestonesJson '["Build MVP","Launch landing page","Acquire first customer"]'

    $Created.Add([pscustomobject]@{ type="launch"; id=[string]$Launch.launch_plan_id })
    Write-Host "[LAUNCH OK] $($Launch.launch_plan_id)" -ForegroundColor Green

    $Index = & ".\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1"

    if (
        [int]$Index.idea_count -lt 1 -or
        [int]$Index.research_record_count -lt 1 -or
        [int]$Index.validation_experiment_count -lt 1 -or
        [int]$Index.launch_plan_count -lt 1
    ) {
        throw "Business Incubator index did not contain certification records."
    }

    Write-Host "[INDEX OK] Incubator aggregation passed." -ForegroundColor Green
}
catch {
    Write-Host "[INCUBATOR ERR] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add($_.Exception.Message)
}

foreach ($Item in $Created) {
    $Path = ""

    switch ([string]$Item.type) {
        "idea" { $Path = ".\workspace\business-incubator\ideas\$($Item.id).json" }
        "score" { $Path = ".\workspace\business-incubator\scores\$($Item.id).json" }
        "research" { $Path = ".\workspace\business-incubator\research\$($Item.id).json" }
        "validation" { $Path = ".\workspace\business-incubator\validation\$($Item.id).json" }
        "launch" { $Path = ".\workspace\business-incubator\launch-plans\$($Item.id).json" }
    }

    if ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

& ".\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1" | Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "$($Errors.Count) Business Incubator architecture error(s) found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.8 Part A Business Incubator Architecture checks passed." -ForegroundColor Green
