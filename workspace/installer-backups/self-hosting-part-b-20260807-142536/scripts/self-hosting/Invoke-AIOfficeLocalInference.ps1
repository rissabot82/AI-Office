param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [string]$Model = "",
    [switch]$DoNotPersist
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeLocalInference.Common.ps1"

$Policy = Get-AIOfficeLocalInferencePolicy

if ([string]::IsNullOrWhiteSpace($Model)) {
    $Model = [string]$Policy.default_model
}

$Started = Get-Date

$Body = [ordered]@{
    model = $Model
    prompt = $Prompt
    stream = $false
}

$Response = Invoke-AIOfficeOllamaApi `
    -Path "/api/generate" `
    -Method "POST" `
    -Body $Body `
    -TimeoutSeconds ([int]$Policy.runtime.request_timeout_seconds)

$ElapsedMs = [math]::Round(((Get-Date) - $Started).TotalMilliseconds,0)
$Id = New-AIOfficeSelfHostingId -Prefix "SHINF"

$Record = [ordered]@{
    inference_id = $Id
    provider_type = "ollama"
    model = $Model
    prompt = $Prompt
    response = [string]$Response.response
    status = "completed"
    metrics = [ordered]@{
        elapsed_ms = $ElapsedMs
        total_duration_ns = if ($null -ne $Response.total_duration) { [int64]$Response.total_duration } else { 0 }
        prompt_eval_count = if ($null -ne $Response.prompt_eval_count) { [int]$Response.prompt_eval_count } else { 0 }
        eval_count = if ($null -ne $Response.eval_count) { [int]$Response.eval_count } else { 0 }
    }
    created_at = (Get-Date).ToString("o")
}

if (-not $DoNotPersist) {
    Write-AIOfficeSelfHostingJson `
        -Value $Record `
        -Path "E:\AI\AI-Office\workspace\self-hosting\inference-results\$Id.json"
}

Write-Host "Local inference completed: $Id | $Model | ${ElapsedMs}ms" -ForegroundColor Green
return [pscustomobject]$Record
