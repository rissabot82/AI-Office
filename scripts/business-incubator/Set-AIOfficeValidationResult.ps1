param(
    [Parameter(Mandatory=$true)][string]$ExperimentId,
    [Parameter(Mandatory=$true)][double]$Score,
    [string]$MetricsJson = "{}",
    [string]$Conclusion = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeVenturePlanning.Common.ps1"

$Policy = Get-AIOfficeVenturePlanningPolicy

$ExperimentPath = "E:\AI\AI-Office\workspace\business-incubator\validation\$ExperimentId.json"
$Experiment = Read-AIOfficeBusinessJson -Path $ExperimentPath

if ($null -eq $Experiment) {
    throw "Validation experiment not found: $ExperimentId"
}

if ($Score -lt 0 -or $Score -gt 100) {
    throw "Validation result score must be between 0 and 100."
}

try {
    $Metrics = ConvertFrom-Json -InputObject $MetricsJson
}
catch {
    throw "MetricsJson is invalid JSON."
}

$Status = if ($Score -ge [double]$Policy.validation.success_score) {
    "validated"
}
elseif ($Score -ge [double]$Policy.validation.partial_success_score) {
    "partial"
}
else {
    "failed"
}

$Id = New-AIOfficeVenturePlanningId -Prefix "BIZVR"

$Record = [ordered]@{
    validation_result_id = $Id
    experiment_id = $ExperimentId
    idea_id = [string]$Experiment.idea_id
    idea_name = [string]$Experiment.idea_name
    score = [math]::Round($Score,2)
    status = $Status
    metrics = $Metrics
    conclusion = $Conclusion
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\validation-results\$Id.json"

$Experiment.status = $Status
$Experiment.updated_at = (Get-Date).ToString("o")

if ($null -eq $Experiment.PSObject.Properties["results"]) {
    $Experiment | Add-Member -NotePropertyName "results" -NotePropertyValue ([ordered]@{})
}

$Experiment.results = [ordered]@{
    validation_result_id = $Id
    score = [math]::Round($Score,2)
    conclusion = $Conclusion
}

Write-AIOfficeBusinessJson -Value $Experiment -Path $ExperimentPath

Write-Host "Validation result recorded: $Id | $Status | score=$Score" -ForegroundColor Green
return [pscustomobject]$Record
