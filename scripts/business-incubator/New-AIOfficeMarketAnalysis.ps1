param(
    [Parameter(Mandatory=$true)][string]$IdeaId,
    [Parameter(Mandatory=$true)][string]$MarketSummary,
    [string]$CompetitorsJson = "[]",
    [string]$PricingObservationsJson = "[]",
    [string]$DemandSignalsJson = "[]",
    [string]$CustomerPainsJson = "[]"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeVenturePlanning.Common.ps1"

$Idea = Get-AIOfficeBusinessIdeaById -IdeaId $IdeaId

try {
    $Competitors = @((ConvertFrom-Json -InputObject $CompetitorsJson) | ForEach-Object { $_ })
    $Pricing = @((ConvertFrom-Json -InputObject $PricingObservationsJson) | ForEach-Object { $_ })
    $Demand = @((ConvertFrom-Json -InputObject $DemandSignalsJson) | ForEach-Object { $_ })
    $Pains = @((ConvertFrom-Json -InputObject $CustomerPainsJson) | ForEach-Object { $_ })
}
catch {
    throw "Market analysis JSON input is invalid."
}

$Id = New-AIOfficeVenturePlanningId -Prefix "BIZMKT"

$Record = [ordered]@{
    market_analysis_id = $Id
    idea_id = $IdeaId
    idea_name = [string]$Idea.name
    market_summary = $MarketSummary
    competitors = $Competitors
    pricing_observations = $Pricing
    demand_signals = $Demand
    customer_pains = $Pains
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\market-analysis\$Id.json"

Write-Host "Market analysis created: $Id | $($Idea.name)" -ForegroundColor Green
return [pscustomobject]$Record
