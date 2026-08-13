param(
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$TaskType,
    [ValidateSet("private","sensitive","normal","public")][string]$Sensitivity = "normal",
    [ValidateSet("low","medium","high")][string]$Complexity = "medium",
    [ValidateSet("","local_only","local_preferred","balanced","cloud_preferred","cloud_only")][string]$ExplicitMode = "",
    [string]$LocalModel = "",
    [switch]$DoNotPersist
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"

$Decision = & "E:\AI\AI-Office\scripts\self-hosting\Get-AIOfficeModelRoutingDecision.ps1" `
    -TaskType $TaskType `
    -Sensitivity $Sensitivity `
    -Complexity $Complexity `
    -ExplicitMode $ExplicitMode `
    -LocalModel $LocalModel `
    -DoNotPersist:$DoNotPersist

$Id = New-AIOfficeSelfHostingId -Prefix "SHHYB"
$FallbackUsed = $false
$Provider = [string]$Decision.selected_provider
$Model = [string]$Decision.selected_model
$ResponseText = ""
$Status = "completed"

try {
    if ($Provider -eq "ollama") {
        $Local = & "E:\AI\AI-Office\scripts\self-hosting\Invoke-AIOfficeLocalInference.ps1" `
            -Prompt $Prompt `
            -Model $Model `
            -DoNotPersist

        $ResponseText = [string]$Local.response
    }
    elseif ($Provider -eq "openclaw") {
        $BridgeScript = "E:\AI\AI-Office\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1"

        if (-not (Test-Path -LiteralPath $BridgeScript -PathType Leaf)) {
            throw "OpenClaw bridge execution script is unavailable."
        }

        $ResponseText = "CLOUD_EXECUTION_ROUTE_READY"
    }
    else {
        throw "Unsupported execution provider: $Provider"
    }
}
catch {
    if (
        $Provider -eq "ollama" -and
        [string]$Decision.selected_mode -ne "local_only"
    ) {
        $FallbackUsed = $true
        $Provider = "openclaw"
        $Model = ""
        $ResponseText = "CLOUD_FALLBACK_ROUTE_READY"
        $Status = "fallback_ready"
    }
    else {
        throw
    }
}

$Record = [ordered]@{
    hybrid_execution_id = $Id
    routing_decision_id = [string]$Decision.routing_decision_id
    provider = $Provider
    model = $Model
    status = $Status
    prompt = $Prompt
    response = $ResponseText
    fallback_used = $FallbackUsed
    created_at = (Get-Date).ToString("o")
}

if (-not $DoNotPersist) {
    Write-AIOfficeSelfHostingJson `
        -Value $Record `
        -Path "E:\AI\AI-Office\workspace\self-hosting\hybrid-results\$Id.json"
}

Write-Host "Hybrid execution: $Id | provider=$Provider | status=$Status" -ForegroundColor Green
return [pscustomobject]$Record
