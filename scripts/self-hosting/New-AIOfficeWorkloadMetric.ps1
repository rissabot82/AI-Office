param(
    [Parameter(Mandatory=$true)][string]$Provider,
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][string]$TaskType,
    [Parameter(Mandatory=$true)][string]$Status,
    [double]$ElapsedMs = 0,
    [int]$PromptTokens = 0,
    [int]$ResponseTokens = 0,
    [string]$MetadataJson = "{}"
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

try {
    $Metadata = ConvertFrom-Json -InputObject $MetadataJson
}
catch {
    throw "MetadataJson is invalid JSON."
}

$Id = New-AIOfficeSelfHostingId -Prefix "SHMET"

$Metric = [ordered]@{
    workload_metric_id = $Id
    provider = $Provider
    model = $Model
    task_type = $TaskType
    status = $Status
    elapsed_ms = [math]::Round($ElapsedMs, 2)
    prompt_tokens = $PromptTokens
    response_tokens = $ResponseTokens
    metadata = $Metadata
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeSelfHostingJson `
    -Value $Metric `
    -Path "E:\AI\AI-Office\workspace\self-hosting\workload-metrics\$Id.json"

Write-Host "Workload metric recorded: $Id | $Provider | $Model | $Status" -ForegroundColor Green
return [pscustomobject]$Metric
