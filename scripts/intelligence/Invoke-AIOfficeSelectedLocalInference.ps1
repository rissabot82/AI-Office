param(
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][string]$Prompt
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\live-integration-policy.json" `
    -Raw |
    ConvertFrom-Json

$Body = [ordered]@{
    model = $Model
    prompt = $Prompt
    stream = $false
    options = @{
        temperature = [double]$Policy.live_integration.temperature
    }
}

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $Response = Invoke-RestMethod `
        -Uri "http://127.0.0.1:11434/api/generate" `
        -Method Post `
        -ContentType "application/json" `
        -Body ($Body | ConvertTo-Json -Depth 20) `
        -TimeoutSec ([int]$Policy.live_integration.timeout_seconds)

    $Text = [string]$Response.response

    if ([string]::IsNullOrWhiteSpace($Text)) {
        throw "Selected local model returned an empty response."
    }

    return [pscustomobject]@{
        provider = "ollama"
        model = $Model
        response = $Text
        elapsed_ms = [math]::Round($Stopwatch.Elapsed.TotalMilliseconds,2)
        optimized_execution_id = ""
        source = "v2.5-intelligent-selection"
        ollama_metrics = [pscustomobject]@{
            total_duration_ns = [long]$Response.total_duration
            load_duration_ns = [long]$Response.load_duration
            prompt_eval_count = [int]$Response.prompt_eval_count
            prompt_eval_duration_ns = [long]$Response.prompt_eval_duration
            eval_count = [int]$Response.eval_count
            eval_duration_ns = [long]$Response.eval_duration
            done_reason = [string]$Response.done_reason
        }
    }
}
finally {
    $Stopwatch.Stop()
}
