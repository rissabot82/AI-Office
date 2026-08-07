param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$OpportunityType,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$TargetCustomer = "",
    [string]$Problem = "",
    [string]$Solution = "",
    [string]$RevenueModel = "",
    [double]$EstimatedStartupCost = 0.0,
    [double]$EstimatedMonthlyRevenue = 0.0,
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

$Policy = Get-AIOfficeBusinessIncubatorPolicy

if (@($Policy.opportunity_types) -notcontains $OpportunityType) {
    throw "Unsupported opportunity type: $OpportunityType"
}

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeBusinessId -Prefix "BIZIDEA"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    idea_id = $Id
    name = $Name
    opportunity_type = $OpportunityType
    status = "captured"
    summary = $Summary
    target_customer = $TargetCustomer
    problem = $Problem
    solution = $Solution
    revenue_model = $RevenueModel
    estimated_startup_cost = [math]::Round([math]::Abs($EstimatedStartupCost),2)
    estimated_monthly_revenue = [math]::Round([math]::Abs($EstimatedMonthlyRevenue),2)
    metadata = $Metadata
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\ideas\$Id.json"

& "E:\AI\AI-Office\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1" | Out-Null

Write-Host "Business idea created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
