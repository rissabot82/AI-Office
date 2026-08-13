param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$TaskType,
    [ValidateSet("private","sensitive","normal","public")][string]$Sensitivity = "normal",
    [ValidateSet("low","medium","high")][string]$Complexity = "medium",
    [ValidateSet("quick","balanced","quality")][string]$WorkloadProfile = "balanced",
    [switch]$DoNotPersist
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Selection = & "E:\AI\AI-Office\scripts\self-hosting\Get-AIOfficeIntelligentModelSelection.ps1" `
    -TaskType $TaskType `
    -Sensitivity $Sensitivity `
    -Complexity $Complexity `
    -WorkloadProfile $WorkloadProfile `
    -DoNotPersist:$DoNotPersist

$Started = Get-Date
$Provider = [string]$Selection.selected_provider
$Model = [string]$Selection.selected_model
$ResponseText = ""
$Status = "completed"

try {
    if ($Provider -eq "ollama") {
        $Result = & "E:\AI\AI-Office\scripts\self-hosting\Invoke-AIOfficeLocalInference.ps1" `
            -Prompt $Prompt `
            -Model $Model `
            -DoNotPersist

        $ResponseText = [string]$Result.response
    }
    elseif ($Provider -eq "openclaw") {
        $ResponseText = "CLOUD_OPTIMIZED_ROUTE_READY"
        $Status = "route_ready"
    }
    else {
        throw "Unsupported selected provider: $Provider"
    }
}
catch {
    $Status = "failed"

    if (-not $DoNotPersist) {
        & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeWorkloadMetric.ps1" `
            -Provider $Provider `
            -Model $Model `
            -TaskType $TaskType `
            -Status "failed" `
            -ElapsedMs ((Get-Date) - $Started).TotalMilliseconds |
            Out-Null
    }

    throw
}

$ElapsedMs = ((Get-Date) - $Started).TotalMilliseconds

if (-not $DoNotPersist) {
    & "E:\AI\AI-Office\scripts\self-hosting\New-AIOfficeWorkloadMetric.ps1" `
        -Provider $Provider `
        -Model $Model `
        -TaskType $TaskType `
        -Status $Status `
        -ElapsedMs $ElapsedMs |
        Out-Null
}

$ExecutionId = New-AIOfficeSelfHostingId -Prefix "SHOPT"

$Execution = [ordered]@{
    optimized_execution_id = $ExecutionId
    model_selection_id = [string]$Selection.model_selection_id
    provider = $Provider
    model = $Model
    status = $Status
    task_type = $TaskType
    workload_profile = $WorkloadProfile
    elapsed_ms = [math]::Round($ElapsedMs,2)
    prompt = $Prompt
    response = $ResponseText
    created_at = (Get-Date).ToString("o")
}

if (-not $DoNotPersist) {
    Write-AIOfficeSelfHostingJson `
        -Value $Execution `
        -Path "E:\AI\AI-Office\workspace\self-hosting\optimized-results\$ExecutionId.json"
}

Write-Host "Optimized inference: $ExecutionId | $Provider | $Model | $Status" -ForegroundColor Green
return [pscustomobject]$Execution
