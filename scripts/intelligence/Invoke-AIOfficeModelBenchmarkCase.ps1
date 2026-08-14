param(
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][string]$CaseId,
    [Parameter(Mandatory=$true)][string]$Family,
    [Parameter(Mandatory=$true)][string]$QualityTier,
    [Parameter(Mandatory=$true)][string]$Prompt,
    [switch]$Persist
)

$ErrorActionPreference = "Stop"

$BenchmarkId = "INTBENCH-" +
    (Get-Date -Format "yyyyMMdd-HHmmss") +
    "-" +
    ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$Status = "completed"
$ResponseText = ""
$ErrorText = ""
$OllamaMetrics = $null

try {
    $Body = [ordered]@{
        model = $Model
        prompt = $Prompt
        stream = $false
        options = @{
            temperature = 0.2
        }
    }

    $ApiResponse = Invoke-RestMethod `
        -Uri "http://127.0.0.1:11434/api/generate" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($Body | ConvertTo-Json -Depth 20) `
        -TimeoutSec 180

    $ResponseText = [string]$ApiResponse.response

    if ([string]::IsNullOrWhiteSpace($ResponseText)) {
        throw "Model returned an empty benchmark response."
    }

    $OllamaMetrics = [ordered]@{
        total_duration_ns = [long]$ApiResponse.total_duration
        load_duration_ns = [long]$ApiResponse.load_duration
        prompt_eval_count = [int]$ApiResponse.prompt_eval_count
        prompt_eval_duration_ns = [long]$ApiResponse.prompt_eval_duration
        eval_count = [int]$ApiResponse.eval_count
        eval_duration_ns = [long]$ApiResponse.eval_duration
        done_reason = [string]$ApiResponse.done_reason
    }
}
catch {
    $Status = "failed"
    $ErrorText = $_.Exception.Message
}
finally {
    $Stopwatch.Stop()
}

$Result = [ordered]@{
    benchmark_id = $BenchmarkId
    model = $Model
    provider = "ollama"
    case_id = $CaseId
    family = $Family
    quality_tier = $QualityTier
    status = $Status
    elapsed_ms = [math]::Round($Stopwatch.Elapsed.TotalMilliseconds,2)
    prompt = $Prompt
    response = $ResponseText
    error = $ErrorText
    ollama_metrics = $OllamaMetrics
    created_at = (Get-Date).ToString("o")
}

if ($Persist) {
    $Directory = "E:\AI\AI-Office\workspace\intelligence\benchmarks"
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null

    $Result |
        ConvertTo-Json -Depth 50 |
        Set-Content `
            -LiteralPath (Join-Path $Directory ($BenchmarkId + ".json")) `
            -Encoding UTF8
}

return [pscustomobject]$Result
