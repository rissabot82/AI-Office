param(
    [Parameter(Mandatory=$true)][string]$ExecutionId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridgeResults.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$ExecutionPath = Join-Path `
    ".\workspace\bridge\executions" `
    ($ExecutionId + ".json")

$Execution = Read-AIOfficeBridgeJson -Path $ExecutionPath

if ($null -eq $Execution) {
    throw "Execution record not found: $ExecutionId"
}

$Manifest = & ".\scripts\bridge\New-AIOfficeArtifactManifest.ps1" `
    -ExecutionId $ExecutionId

$Summary = Get-AIOfficeResultSummary -Execution $Execution
$NormalizedId = New-AIOfficeNormalizedResultId

$Normalized = [ordered]@{
    normalized_result_id = $NormalizedId
    execution_id = $ExecutionId
    bridge_request_id = [string]$Execution.bridge_request_id
    message_id = [string]$Execution.message_id
    status = [string]$Execution.status
    created_at = (Get-Date).ToString("o")
    summary = $Summary
    data = [ordered]@{
        run_id = [string]$Execution.run_id
        session_key = [string]$Execution.session_key
        gateway_url = [string]$Execution.gateway_url
        started_at = $Execution.started_at
        completed_at = $Execution.completed_at
        response_payload = $Execution.response_payload
        error = $Execution.error
    }
    artifacts = @($Manifest.artifacts)
}

$Path = Join-Path `
    ".\workspace\bridge\results\normalized" `
    ($NormalizedId + ".json")

Write-AIOfficeBridgeJson -Value $Normalized -Path $Path

Write-Host "Normalized result created: $NormalizedId" `
    -ForegroundColor Green

return [pscustomobject]$Normalized
