param(
    [string]$Model = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeModelSelection.Common.ps1"

if ([string]::IsNullOrWhiteSpace($Model)) {
    try {
        $RuntimePolicy = Get-Content `
            -LiteralPath "E:\AI\AI-Office\config\self-hosting\runtime-policy.json" `
            -Raw |
            ConvertFrom-Json

        $Model = [string]$RuntimePolicy.default_model
    }
    catch {
        $Model = "qwen2.5:3b"
    }
}

$Tests = @(
    [ordered]@{
        name = "classification"
        task_type = "classification"
        prompt = "Reply with one word only: classify 'A customer wants a lower monthly car payment' as SALES or SERVICE."
    },
    [ordered]@{
        name = "summarization"
        task_type = "summarization"
        prompt = "Summarize in one short sentence: AI Office can route workloads between local and cloud models."
    },
    [ordered]@{
        name = "drafting"
        task_type = "drafting"
        prompt = "Write a five-word automotive summer sale headline."
    }
)

$Results = New-Object System.Collections.Generic.List[object]

foreach ($Test in $Tests) {
    $Started = Get-Date

    try {
        $Inference = & "E:\AI\AI-Office\scripts\self-hosting\Invoke-AIOfficeLocalInference.ps1" `
            -Prompt ([string]$Test.prompt) `
            -Model $Model `
            -DoNotPersist

        $ElapsedMs = ((Get-Date) - $Started).TotalMilliseconds

        $Results.Add([pscustomobject]@{
            name = [string]$Test.name
            task_type = [string]$Test.task_type
            status = "completed"
            elapsed_ms = [math]::Round($ElapsedMs,2)
            response = [string]$Inference.response
        })

        & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeWorkloadMetric.ps1" `
            -Provider "ollama" `
            -Model $Model `
            -TaskType ([string]$Test.task_type) `
            -Status "completed" `
            -ElapsedMs $ElapsedMs |
            Out-Null
    }
    catch {
        $ElapsedMs = ((Get-Date) - $Started).TotalMilliseconds

        $Results.Add([pscustomobject]@{
            name = [string]$Test.name
            task_type = [string]$Test.task_type
            status = "failed"
            elapsed_ms = [math]::Round($ElapsedMs,2)
            response = $_.Exception.Message
        })

        & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeWorkloadMetric.ps1" `
            -Provider "ollama" `
            -Model $Model `
            -TaskType ([string]$Test.task_type) `
            -Status "failed" `
            -ElapsedMs $ElapsedMs |
            Out-Null
    }
}

$Completed = @($Results | Where-Object { [string]$_.status -eq "completed" }).Count
$Average = ($Results | Measure-Object -Property elapsed_ms -Average).Average
$BenchmarkId = New-AIOfficeSelfHostingId -Prefix "SHBENCH"

$Benchmark = [ordered]@{
    benchmark_id = $BenchmarkId
    model = $Model
    provider = "ollama"
    status = if ($Completed -eq $Results.Count) { "completed" } else { "partial" }
    tests = @($Results | ForEach-Object { $_ })
    summary = [ordered]@{
        total_tests = $Results.Count
        completed_tests = $Completed
        failed_tests = $Results.Count - $Completed
        average_elapsed_ms = if ($null -ne $Average) { [math]::Round([double]$Average,2) } else { 0 }
        success_rate = if ($Results.Count -gt 0) { [math]::Round(([double]$Completed / [double]$Results.Count) * 100,2) } else { 0 }
    }
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeSelfHostingJson `
    -Value $Benchmark `
    -Path "E:\AI\AI-Office\workspace\self-hosting\benchmarks\$BenchmarkId.json"

Write-Host "Local model benchmark completed: $BenchmarkId | $Model | success=$($Benchmark.summary.success_rate)%" -ForegroundColor Green
return [pscustomobject]$Benchmark
