param(
    [Parameter(Mandatory=$true)][string]$IdeaId,
    [Parameter(Mandatory=$true)][string]$DimensionsJson
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

$IdeaPath = "E:\AI\AI-Office\workspace\business-incubator\ideas\$IdeaId.json"
$Idea = Read-AIOfficeBusinessJson -Path $IdeaPath

if ($null -eq $Idea) {
    throw "Business idea not found: $IdeaId"
}

try {
    $Dimensions = @((ConvertFrom-Json -InputObject $DimensionsJson) | ForEach-Object { $_ })
}
catch {
    throw "DimensionsJson is invalid JSON."
}

if ($Dimensions.Count -lt 1) {
    throw "At least one scoring dimension is required."
}

$WeightedTotal = 0.0
$WeightTotal = 0.0
$Normalized = New-Object System.Collections.Generic.List[object]

foreach ($Dimension in $Dimensions) {
    $Name = [string]$Dimension.name
    $Score = [double]$Dimension.score
    $Weight = if ($null -ne $Dimension.PSObject.Properties["weight"]) {
        [double]$Dimension.weight
    } else {
        1.0
    }

    if ($Score -lt 0 -or $Score -gt 100) {
        throw "Opportunity scores must be between 0 and 100."
    }

    if ($Weight -lt 0) {
        throw "Opportunity score weights cannot be negative."
    }

    $WeightedTotal += ($Score * $Weight)
    $WeightTotal += $Weight

    $Normalized.Add([pscustomobject]@{
        name = $Name
        score = $Score
        weight = $Weight
    })
}

if ($WeightTotal -le 0) {
    throw "Total opportunity score weight must be greater than zero."
}

$TotalScore = [math]::Round(($WeightedTotal / $WeightTotal),2)
$Id = New-AIOfficeBusinessId -Prefix "BIZSCORE"

$Record = [ordered]@{
    score_id = $Id
    idea_id = $IdeaId
    idea_name = [string]$Idea.name
    total_score = $TotalScore
    dimensions = @($Normalized | ForEach-Object { $_ })
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\scores\$Id.json"

& "E:\AI\AI-Office\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1" | Out-Null

Write-Host "Opportunity score created: $Id | score=$TotalScore" -ForegroundColor Green
return [pscustomobject]$Record
