param(
    [Parameter(Mandatory=$true)][string]$IdeaId,
    [Parameter(Mandatory=$true)][string]$Method,
    [Parameter(Mandatory=$true)][string]$Hypothesis,
    [Parameter(Mandatory=$true)][string]$SuccessMetric
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

$Policy = Get-AIOfficeBusinessIncubatorPolicy

if (@($Policy.validation_methods) -notcontains $Method) {
    throw "Unsupported validation method: $Method"
}

$Idea = Read-AIOfficeBusinessJson `
    -Path "E:\AI\AI-Office\workspace\business-incubator\ideas\$IdeaId.json"

if ($null -eq $Idea) {
    throw "Business idea not found: $IdeaId"
}

$Id = New-AIOfficeBusinessId -Prefix "BIZVAL"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    experiment_id = $Id
    idea_id = $IdeaId
    idea_name = [string]$Idea.name
    method = $Method
    hypothesis = $Hypothesis
    success_metric = $SuccessMetric
    status = "planned"
    results = [ordered]@{}
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\validation\$Id.json"

& "E:\AI\AI-Office\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1" | Out-Null

Write-Host "Validation experiment created: $Id | $Method" -ForegroundColor Green
return [pscustomobject]$Record
