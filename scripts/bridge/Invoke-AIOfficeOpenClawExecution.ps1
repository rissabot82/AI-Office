param(
    [Parameter(Mandatory=$true)]
    [string]$BridgeRequestId,

    [string]$SessionKey = "ai-office-bridge",

    [string]$AgentId = "",

    [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")
. (Join-Path $PSScriptRoot "AIOfficeOpenClaw.Transport.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$RequestPath = Join-Path `
    ".\workspace\bridge\requests" `
    ($BridgeRequestId + ".json")

$Request = Read-AIOfficeBridgeJson -Path $RequestPath

if ($null -eq $Request) {
    throw "Bridge request not found: $BridgeRequestId"
}

$Validation = & ".\scripts\bridge\Test-AIOfficeBridgeRequest.ps1" `
    -BridgeRequestId $BridgeRequestId

if (-not [bool]$Validation.valid) {
    throw "Bridge request is not approved or valid."
}

$Policy = Get-AIOfficeBridgeExecutionPolicy
$BridgePolicy = Get-AIOfficeBridgePolicy

if ($TimeoutSeconds -gt [int]$BridgePolicy.execution.maximum_timeout_seconds) {
    $TimeoutSeconds = [int]$BridgePolicy.execution.maximum_timeout_seconds
}

$ExecutionId = New-AIOfficeExecutionId
$Now = (Get-Date).ToString("o")

$Execution = [ordered]@{
    execution_id = $ExecutionId
    bridge_request_id = $BridgeRequestId
    message_id = [string]$Request.message_id
    status = "starting"
    gateway_url = [string]$BridgePolicy.transport.url
    method = [string]$Policy.agent_execution.start_method
    run_id = ""
    session_key = $SessionKey
    created_at = $Now
    updated_at = $Now
    started_at = $Now
    completed_at = $null
    request_payload = $Request.payload
    response_payload = $null
    error = $null
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "execution_started"
            actor = "openclaw-bridge"
            details = "Approved request submitted to OpenClaw."
        }
    )
}

$ExecutionPath = Join-Path `
    ".\workspace\bridge\executions" `
    ($ExecutionId + ".json")

Write-AIOfficeBridgeJson `
    -Value $Execution `
    -Path $ExecutionPath

try {
    $Prompt = ""

    if ($null -ne $Request.payload.PSObject.Properties["prompt"]) {
        $Prompt = [string]$Request.payload.prompt
    }
    elseif ($null -ne $Request.payload.PSObject.Properties["instruction"]) {
        $Prompt = [string]$Request.payload.instruction
    }
    else {
        $Prompt = (
            "Execute this approved AI Office action: " +
            [string]$Request.action_type +
            ". Payload: " +
            ($Request.payload | ConvertTo-Json -Depth 20 -Compress)
        )
    }

    $IdempotencyKey = (
        [string]$Policy.agent_execution.idempotency_prefix +
        "-" +
        $ExecutionId
    )

    $AgentParams = [ordered]@{
        sessionKey = $SessionKey
        message = $Prompt
        idempotencyKey = $IdempotencyKey
    }

    if (-not [string]::IsNullOrWhiteSpace($AgentId)) {
        $AgentParams.agentId = $AgentId
    }

    $StartPayload = Invoke-AIOfficeOpenClawRpc `
        -Method ([string]$Policy.agent_execution.start_method) `
        -Params $AgentParams `
        -TimeoutSeconds $TimeoutSeconds

    $RunId = ""

    if ($null -ne $StartPayload.PSObject.Properties["runId"]) {
        $RunId = [string]$StartPayload.runId
    }
    elseif ($null -ne $StartPayload.PSObject.Properties["id"]) {
        $RunId = [string]$StartPayload.id
    }

    $Execution.run_id = $RunId
    $Execution.status = "running"
    $Execution.updated_at = (Get-Date).ToString("o")
    $Execution.response_payload = $StartPayload

    Write-AIOfficeBridgeJson `
        -Value $Execution `
        -Path $ExecutionPath

    if (-not [string]::IsNullOrWhiteSpace($RunId)) {
        $WaitParams = [ordered]@{
            runId = $RunId
        }

        $WaitPayload = Invoke-AIOfficeOpenClawRpc `
            -Method ([string]$Policy.agent_execution.wait_method) `
            -Params $WaitParams `
            -TimeoutSeconds $TimeoutSeconds

        $Execution.response_payload = $WaitPayload
    }

    $Execution.status = "completed"
    $Execution.completed_at = (Get-Date).ToString("o")
    $Execution.updated_at = $Execution.completed_at

    $History = New-Object System.Collections.Generic.List[object]

    foreach ($Entry in @($Execution.history)) {
        $History.Add($Entry)
    }

    $History.Add([ordered]@{
        timestamp = $Execution.completed_at
        action = "execution_completed"
        actor = "openclaw-bridge"
        details = "OpenClaw execution completed."
    })

    $Execution.history = @($History | ForEach-Object { $_ })

    Write-AIOfficeBridgeJson `
        -Value $Execution `
        -Path $ExecutionPath

    & ".\scripts\messaging\Complete-AIOfficeMessage.ps1" `
        -MessageId ([string]$Request.message_id) `
        -Actor "openclaw-bridge" `
        -Details "OpenClaw execution completed." |
        Out-Null

    Write-Host "OpenClaw execution completed: $ExecutionId" `
        -ForegroundColor Green

    return [pscustomobject]$Execution
}
catch {
    $CompletedAt = (Get-Date).ToString("o")
    $Execution.status = "failed"
    $Execution.completed_at = $CompletedAt
    $Execution.updated_at = $CompletedAt
    $Execution.error = [ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }

    $History = New-Object System.Collections.Generic.List[object]

    foreach ($Entry in @($Execution.history)) {
        $History.Add($Entry)
    }

    $History.Add([ordered]@{
        timestamp = $CompletedAt
        action = "execution_failed"
        actor = "openclaw-bridge"
        details = $_.Exception.Message
    })

    $Execution.history = @($History | ForEach-Object { $_ })

    Write-AIOfficeBridgeJson `
        -Value $Execution `
        -Path $ExecutionPath

    try {
        & ".\scripts\messaging\Fail-AIOfficeMessage.ps1" `
            -MessageId ([string]$Request.message_id) `
            -Reason $_.Exception.Message `
            -Actor "openclaw-bridge" |
            Out-Null
    }
    catch {
    }

    throw
}
finally {
    & ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
        Out-Null
}
