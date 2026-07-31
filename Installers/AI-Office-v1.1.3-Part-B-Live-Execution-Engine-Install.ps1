# ============================================================
# AI Office v1.1.3 - Part B
# OpenClaw Live Execution Engine
# Repository: E:\AI\AI-Office
# Requires: v1.1.3 Part A
# ============================================================

$ErrorActionPreference = "Stop"
$Repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $Repository -PathType Container)) {
    throw "AI Office repository not found at $Repository"
}

Set-Location $Repository

$RequiredPrevious = @(
    ".\config\bridge\bridge-identity.json",
    ".\config\bridge\bridge-policy.json",
    ".\scripts\bridge\AIOfficeBridge.Common.ps1",
    ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1",
    ".\scripts\bridge\Test-AIOfficeBridgeRequest.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1"
)

foreach ($RequiredPath in $RequiredPrevious) {
    if (-not (Test-Path -LiteralPath $RequiredPath -PathType Leaf)) {
        throw "AI Office v1.1.3 Part A is required. Missing: $RequiredPath"
    }
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function Write-NewFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $Parent = Split-Path -Parent $Path

        if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
            New-Item -ItemType Directory -Path $Parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

@(
    ".\workspace\bridge\sessions",
    ".\workspace\bridge\executions",
    ".\workspace\bridge\events",
    ".\workspace\bridge\failed"
) | ForEach-Object { Ensure-Directory $_ }

$Now = (Get-Date).ToString("o")

$ExecutionPolicy = @"
{
  "schema_version": "1.0.0",
  "version": "1.1.3",
  "part": "B",
  "client": {
    "id": "gateway-client",
    "version": "1.1.3",
    "platform": "windows",
    "mode": "backend",
    "role": "operator",
    "scopes": [
      "operator.read",
      "operator.write"
    ],
    "caps": [
      "tool-events"
    ],
    "locale": "en-US",
    "user_agent": "ai-office-openclaw-bridge/1.1.3"
  },
  "protocol": {
    "minimum": 4,
    "maximum": 4,
    "challenge_timeout_seconds": 5,
    "connect_timeout_seconds": 10,
    "request_timeout_seconds": 300,
    "receive_buffer_bytes": 65536
  },
  "authentication": {
    "mode": "token",
    "environment_variable": "OPENCLAW_GATEWAY_TOKEN",
    "allow_empty_for_health_check": true,
    "persist_token": false
  },
  "agent_execution": {
    "start_method": "agent",
    "wait_method": "agent.wait",
    "default_session_key": "ai-office-bridge",
    "default_agent_id": "",
    "default_timeout_seconds": 300,
    "idempotency_prefix": "AIO-BRIDGE"
  },
  "updated_at": "$Now"
}
"@

Write-NewFile ".\config\bridge\execution-policy.json" $ExecutionPolicy

$ExecutionSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/openclaw-execution-record-schema.json",
  "title": "AI Office OpenClaw Execution Record",
  "type": "object",
  "required": [
    "execution_id",
    "bridge_request_id",
    "message_id",
    "status",
    "gateway_url",
    "method",
    "created_at",
    "updated_at",
    "history"
  ],
  "properties": {
    "execution_id": {
      "type": "string",
      "pattern": "^EXE-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "bridge_request_id": {
      "type": "string"
    },
    "message_id": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "gateway_url": {
      "type": "string"
    },
    "method": {
      "type": "string"
    },
    "run_id": {
      "type": "string"
    },
    "session_key": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    },
    "started_at": {
      "type": ["string", "null"]
    },
    "completed_at": {
      "type": ["string", "null"]
    },
    "request_payload": {
      "type": "object"
    },
    "response_payload": {
      "type": ["object", "null"]
    },
    "error": {
      "type": ["object", "null"]
    },
    "history": {
      "type": "array"
    }
  }
}
'@

Write-NewFile ".\config\bridge\execution-record-schema.json" $ExecutionSchema

$ExecutionTemplate = @'
{
  "execution_id": "EXE-YYYYMMDD-HHMMSS-ABC123",
  "bridge_request_id": "BRQ-YYYYMMDD-HHMMSS-ABC123",
  "message_id": "MSG-YYYYMMDD-HHMMSS-ABC123",
  "status": "queued",
  "gateway_url": "ws://localhost:18789",
  "method": "agent",
  "run_id": "",
  "session_key": "ai-office-bridge",
  "created_at": "",
  "updated_at": "",
  "started_at": null,
  "completed_at": null,
  "request_payload": {},
  "response_payload": null,
  "error": null,
  "history": []
}
'@

Write-NewFile ".\workspace\templates\openclaw-execution-record-template.json" $ExecutionTemplate

$Transport = @'
# AI Office OpenClaw WebSocket transport
# PowerShell 5.1 compatible

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

function Get-AIOfficeBridgeExecutionPolicy {
    $Root = Get-AIOfficeBridgeRoot

    return Read-AIOfficeBridgeJson `
        -Path (Join-Path $Root "config\bridge\execution-policy.json")
}

function Get-AIOfficeGatewayToken {
    $Policy = Get-AIOfficeBridgeExecutionPolicy
    $VariableName = [string]$Policy.authentication.environment_variable

    if ([string]::IsNullOrWhiteSpace($VariableName)) {
        return ""
    }

    return [string][Environment]::GetEnvironmentVariable(
        $VariableName,
        "Process"
    )
}

function New-AIOfficeExecutionId {
    return (
        "EXE-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeRpcId {
    return (
        "RPC-" +
        ([guid]::NewGuid().ToString("N").Substring(0,16)).ToUpperInvariant()
    )
}

function Send-AIOfficeWebSocketText {
    param(
        [Parameter(Mandatory=$true)]
        [System.Net.WebSockets.ClientWebSocket]$Socket,

        [Parameter(Mandatory=$true)]
        [string]$Text,

        [Parameter(Mandatory=$true)]
        [System.Threading.CancellationToken]$CancellationToken
    )

    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $Segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$Bytes)

    $Task = $Socket.SendAsync(
        $Segment,
        [System.Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        $CancellationToken
    )

    $Task.GetAwaiter().GetResult()
}

function Receive-AIOfficeWebSocketText {
    param(
        [Parameter(Mandatory=$true)]
        [System.Net.WebSockets.ClientWebSocket]$Socket,

        [Parameter(Mandatory=$true)]
        [System.Threading.CancellationToken]$CancellationToken,

        [int]$BufferBytes = 65536
    )

    $Stream = New-Object System.IO.MemoryStream

    try {
        do {
            $Buffer = New-Object byte[] $BufferBytes
            $Segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$Buffer)

            $Task = $Socket.ReceiveAsync(
                $Segment,
                $CancellationToken
            )

            $Result = $Task.GetAwaiter().GetResult()

            if ($Result.MessageType -eq
                [System.Net.WebSockets.WebSocketMessageType]::Close) {
                throw "OpenClaw Gateway closed the WebSocket connection."
            }

            if ($Result.Count -gt 0) {
                $Stream.Write($Buffer, 0, $Result.Count)
            }
        }
        while (-not $Result.EndOfMessage)

        return [System.Text.Encoding]::UTF8.GetString(
            $Stream.ToArray()
        )
    }
    finally {
        $Stream.Dispose()
    }
}

function Wait-AIOfficeGatewayFrame {
    param(
        [Parameter(Mandatory=$true)]
        [System.Net.WebSockets.ClientWebSocket]$Socket,

        [Parameter(Mandatory=$true)]
        [System.Threading.CancellationToken]$CancellationToken,

        [string]$ExpectedId = "",

        [string]$ExpectedEvent = "",

        [int]$BufferBytes = 65536
    )

    while ($true) {
        $Text = Receive-AIOfficeWebSocketText `
            -Socket $Socket `
            -CancellationToken $CancellationToken `
            -BufferBytes $BufferBytes

        try {
            $Frame = $Text | ConvertFrom-Json
        }
        catch {
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($ExpectedId) -and
            [string]$Frame.type -eq "res" -and
            [string]$Frame.id -eq $ExpectedId) {
            return $Frame
        }

        if (-not [string]::IsNullOrWhiteSpace($ExpectedEvent) -and
            [string]$Frame.type -eq "event" -and
            [string]$Frame.event -eq $ExpectedEvent) {
            return $Frame
        }
    }
}

function Connect-AIOfficeOpenClawGateway {
    param(
        [string]$Token = "",
        [switch]$ReadOnly
    )

    $Policy = Get-AIOfficeBridgeExecutionPolicy
    $BridgePolicy = Get-AIOfficeBridgePolicy

    if ($null -eq $Policy -or $null -eq $BridgePolicy) {
        throw "Bridge execution policy could not be loaded."
    }

    if ([string]::IsNullOrWhiteSpace($Token)) {
        $Token = Get-AIOfficeGatewayToken
    }

    if ([string]::IsNullOrWhiteSpace($Token)) {
        throw (
            "OpenClaw Gateway token is not available. Set the " +
            [string]$Policy.authentication.environment_variable +
            " environment variable for this PowerShell session."
        )
    }

    $Socket = New-Object System.Net.WebSockets.ClientWebSocket
    $TimeoutSeconds = [int]$Policy.protocol.connect_timeout_seconds
    $Cancellation = New-Object System.Threading.CancellationTokenSource
    $Cancellation.CancelAfter(
        [TimeSpan]::FromSeconds($TimeoutSeconds)
    )

    try {
        $Uri = New-Object System.Uri ([string]$BridgePolicy.transport.url)

        $ConnectTask = $Socket.ConnectAsync(
            $Uri,
            $Cancellation.Token
        )

        $ConnectTask.GetAwaiter().GetResult()

        $Challenge = Wait-AIOfficeGatewayFrame `
            -Socket $Socket `
            -CancellationToken $Cancellation.Token `
            -ExpectedEvent "connect.challenge" `
            -BufferBytes ([int]$Policy.protocol.receive_buffer_bytes)

        $Scopes = @("operator.read")

        if (-not $ReadOnly) {
            $Scopes += "operator.write"
        }

        $ConnectId = New-AIOfficeRpcId

        $ConnectFrame = [ordered]@{
            type = "req"
            id = $ConnectId
            method = "connect"
            params = [ordered]@{
                minProtocol = [int]$Policy.protocol.minimum
                maxProtocol = [int]$Policy.protocol.maximum
                client = [ordered]@{
                    id = [string]$Policy.client.id
                    version = [string]$Policy.client.version
                    platform = [string]$Policy.client.platform
                    mode = [string]$Policy.client.mode
                }
                role = [string]$Policy.client.role
                scopes = $Scopes
                caps = @($Policy.client.caps)
                commands = @()
                permissions = [ordered]@{}
                auth = [ordered]@{
                    token = $Token
                }
                locale = [string]$Policy.client.locale
                userAgent = [string]$Policy.client.user_agent
            }
        }

        $ConnectJson = $ConnectFrame |
            ConvertTo-Json -Depth 20 -Compress

        Send-AIOfficeWebSocketText `
            -Socket $Socket `
            -Text $ConnectJson `
            -CancellationToken $Cancellation.Token

        $Response = Wait-AIOfficeGatewayFrame `
            -Socket $Socket `
            -CancellationToken $Cancellation.Token `
            -ExpectedId $ConnectId `
            -BufferBytes ([int]$Policy.protocol.receive_buffer_bytes)

        if (-not [bool]$Response.ok) {
            $Message = "OpenClaw Gateway connection failed."

            if ($null -ne $Response.error -and
                $null -ne $Response.error.message) {
                $Message = [string]$Response.error.message
            }

            throw $Message
        }

        return [pscustomobject]@{
            socket = $Socket
            hello = $Response.payload
            challenge = $Challenge.payload
            cancellation = $Cancellation
        }
    }
    catch {
        $Socket.Dispose()
        $Cancellation.Dispose()
        throw
    }
}

function Invoke-AIOfficeOpenClawRpc {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Method,

        [Parameter(Mandatory=$true)]
        $Params,

        [int]$TimeoutSeconds = 300
    )

    $Connection = Connect-AIOfficeOpenClawGateway

    try {
        $RequestId = New-AIOfficeRpcId
        $Request = [ordered]@{
            type = "req"
            id = $RequestId
            method = $Method
            params = $Params
        }

        $Json = $Request |
            ConvertTo-Json -Depth 30 -Compress

        $RequestCancellation = New-Object System.Threading.CancellationTokenSource
        $RequestCancellation.CancelAfter(
            [TimeSpan]::FromSeconds($TimeoutSeconds)
        )

        try {
            Send-AIOfficeWebSocketText `
                -Socket $Connection.socket `
                -Text $Json `
                -CancellationToken $RequestCancellation.Token

            $Response = Wait-AIOfficeGatewayFrame `
                -Socket $Connection.socket `
                -CancellationToken $RequestCancellation.Token `
                -ExpectedId $RequestId

            if (-not [bool]$Response.ok) {
                $ErrorMessage = "OpenClaw RPC failed."

                if ($null -ne $Response.error -and
                    $null -ne $Response.error.message) {
                    $ErrorMessage = [string]$Response.error.message
                }

                throw $ErrorMessage
            }

            return $Response.payload
        }
        finally {
            $RequestCancellation.Dispose()
        }
    }
    finally {
        try {
            if ($Connection.socket.State -eq
                [System.Net.WebSockets.WebSocketState]::Open) {
                $CloseCancellation = New-Object System.Threading.CancellationTokenSource
                $CloseCancellation.CancelAfter(
                    [TimeSpan]::FromSeconds(2)
                )

                try {
                    $CloseTask = $Connection.socket.CloseAsync(
                        [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
                        "AI Office request completed.",
                        $CloseCancellation.Token
                    )

                    $CloseTask.GetAwaiter().GetResult()
                }
                catch {
                }
                finally {
                    $CloseCancellation.Dispose()
                }
            }
        }
        finally {
            $Connection.socket.Dispose()
            $Connection.cancellation.Dispose()
        }
    }
}
'@

Write-NewFile ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1" $Transport

$Health = @'
param(
    [switch]$Authenticated
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")
. (Join-Path $PSScriptRoot "AIOfficeOpenClaw.Transport.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$BridgePolicy = Get-AIOfficeBridgePolicy
$ExecutionPolicy = Get-AIOfficeBridgeExecutionPolicy

$PortReachable = Test-AIOfficeOpenClawGatewayPort `
    -HostName ([string]$BridgePolicy.transport.host) `
    -Port ([int]$BridgePolicy.transport.port)

$Result = [ordered]@{
    checked_at = (Get-Date).ToString("o")
    gateway_url = [string]$BridgePolicy.transport.url
    port_reachable = $PortReachable
    authenticated = $false
    protocol = $null
    server_version = ""
    scopes = @()
    error = ""
}

if ($Authenticated) {
    try {
        $Connection = Connect-AIOfficeOpenClawGateway -ReadOnly

        try {
            $Result.authenticated = $true
            $Result.protocol = $Connection.hello.protocol
            $Result.server_version = [string]$Connection.hello.server.version
            $Result.scopes = @($Connection.hello.auth.scopes)
        }
        finally {
            $Connection.socket.Dispose()
            $Connection.cancellation.Dispose()
        }
    }
    catch {
        $Result.error = $_.Exception.Message
    }
}

return [pscustomobject]$Result
'@

Write-NewFile ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" $Health

$InvokeExecution = @'
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
'@

Write-NewFile ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1" $InvokeExecution

$Consume = @'
param(
    [int]$Limit = 1,
    [string]$Recipient = "bridge",
    [switch]$Execute
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

for ($Index = 0; $Index -lt $Limit; $Index++) {
    $Message = & ".\scripts\messaging\Receive-AIOfficeMessage.ps1" `
        -Queue "outbox" `
        -Recipient $Recipient

    if ($null -eq $Message) {
        break
    }

    try {
        $PayloadJson = $Message.payload |
            ConvertTo-Json -Depth 30 -Compress

        $RiskLevel = "high"
        $ApprovalStatus = "pending"
        $ActionType = "agent_task"

        if ($null -ne $Message.payload.PSObject.Properties["risk_level"]) {
            $RiskLevel = [string]$Message.payload.risk_level
        }

        if ($null -ne $Message.payload.PSObject.Properties["approval_status"]) {
            $ApprovalStatus = [string]$Message.payload.approval_status
        }

        if ($null -ne $Message.payload.PSObject.Properties["action_type"]) {
            $ActionType = [string]$Message.payload.action_type
        }

        $Request = & ".\scripts\bridge\New-AIOfficeBridgeRequest.ps1" `
            -MessageId ([string]$Message.message_id) `
            -RequestedBy ([string]$Message.from) `
            -ActionType $ActionType `
            -WorkflowId ([string]$Message.workflow_id) `
            -CorrelationId ([string]$Message.correlation_id) `
            -ConversationId ([string]$Message.conversation_id) `
            -RiskLevel $RiskLevel `
            -ApprovalStatus $ApprovalStatus `
            -PayloadJson $PayloadJson

        $Record = [ordered]@{
            message_id = [string]$Message.message_id
            bridge_request_id = [string]$Request.bridge_request_id
            execution_status = "request_created"
            execution_id = ""
            error = ""
        }

        if ($Execute) {
            $Execution = & ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1" `
                -BridgeRequestId ([string]$Request.bridge_request_id)

            $Record.execution_status = [string]$Execution.status
            $Record.execution_id = [string]$Execution.execution_id
        }

        $Results.Add([pscustomobject]$Record)
    }
    catch {
        $Results.Add([pscustomobject]@{
            message_id = [string]$Message.message_id
            bridge_request_id = ""
            execution_status = "failed"
            execution_id = ""
            error = $_.Exception.Message
        })
    }
}

return @($Results | ForEach-Object { $_ })
'@

Write-NewFile ".\scripts\bridge\Receive-AIOfficeBridgeWork.ps1" $Consume

$Test = @'
param(
    [switch]$AuthenticatedConnectionTest
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.1.3 Part B Live Execution Engine..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\bridge\execution-policy.json",
    ".\config\bridge\execution-record-schema.json",
    ".\workspace\templates\openclaw-execution-record-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\bridge\AIOfficeOpenClaw.Transport.ps1",
    ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1",
    ".\scripts\bridge\Invoke-AIOfficeOpenClawExecution.ps1",
    ".\scripts\bridge\Receive-AIOfficeBridgeWork.ps1",
    ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

try {
    $Health = & ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1"

    if (-not [bool]$Health.port_reachable) {
        Write-Host "[PORT WARN  ] Gateway port 18789 is not reachable." `
            -ForegroundColor Yellow
    }
    else {
        Write-Host "[PORT OK    ] Gateway port 18789 is reachable." `
            -ForegroundColor Green
    }
}
catch {
    Write-Host "[PORT ERR   ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Gateway port test failed: " + $_.Exception.Message)
}

if ($AuthenticatedConnectionTest) {
    try {
        $AuthHealth = & ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" `
            -Authenticated

        if (-not [bool]$AuthHealth.authenticated) {
            throw $AuthHealth.error
        }

        Write-Host (
            "[AUTH OK    ] OpenClaw " +
            [string]$AuthHealth.server_version +
            " protocol " +
            [string]$AuthHealth.protocol
        ) -ForegroundColor Green
    }
    catch {
        Write-Host "[AUTH ERR   ] $($_.Exception.Message)" `
            -ForegroundColor Red
        $Errors.Add("Authenticated connection failed: " + $_.Exception.Message)
    }
}
else {
    Write-Host (
        "[AUTH SKIP  ] Set OPENCLAW_GATEWAY_TOKEN and rerun with " +
        "-AuthenticatedConnectionTest for live authentication."
    ) -ForegroundColor Yellow
}

$MessageId = ""
$RequestId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "bridge" `
        -MessageType "execution_request" `
        -Priority "high" `
        -Subject "Part B dry-run validation" `
        -ConversationTopic "BRIDGE-B-VALIDATION" `
        -Queue "outbox" `
        -PayloadJson '{"action_type":"status_check","risk_level":"low","approval_status":"not_required","prompt":"Return gateway status only."}'

    $MessageId = [string]$Message.message_id

    $Records = @(
        & ".\scripts\bridge\Receive-AIOfficeBridgeWork.ps1" `
            -Limit 1
    )

    if ($Records.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$Records[0].bridge_request_id)) {
        throw "Bridge work receiver did not create a request."
    }

    $RequestId = [string]$Records[0].bridge_request_id

    Write-Host "[QUEUE OK   ] $RequestId" -ForegroundColor Green
}
catch {
    Write-Host "[QUEUE ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Bridge queue integration failed: " + $_.Exception.Message)
}

if (-not [string]::IsNullOrWhiteSpace($RequestId)) {
    $Path = ".\workspace\bridge\requests\$RequestId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if (-not [string]::IsNullOrWhiteSpace($MessageId)) {
    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Path = ".\workspace\messages\$Queue\$MessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\bridge\Update-AIOfficeBridgeIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " live execution engine error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.1.3 Part B Live Execution Engine checks passed." `
    -ForegroundColor Green
'@

Write-NewFile ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1" $Test

$Guide = @'
# AI Office v1.1.3 Part B — Live Execution Engine

Part B adds the authenticated OpenClaw Gateway WebSocket transport and the first live execution path.

## Added

- Protocol v4 WebSocket transport
- Gateway challenge handling
- Token authentication through `OPENCLAW_GATEWAY_TOKEN`
- Operator read/write scopes
- Generic OpenClaw RPC client
- Authenticated Gateway health check
- Live `agent` and `agent.wait` execution flow
- Message Bus consumer
- Bridge execution records
- Message completion and failure updates
- Dry-run and authenticated validation

## Security

The Gateway token is never stored in the repository. It must be supplied through the current PowerShell process:

```powershell
$env:OPENCLAW_GATEWAY_TOKEN = "PASTE_TOKEN_HERE"
```

Do not commit or save the token in a script.

## Standard validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1"
```

## Authenticated validation

After setting the token in the same PowerShell window:

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1" `
    -AuthenticatedConnectionTest
```

## Test Gateway connection only

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\bridge\Test-AIOfficeOpenClawConnection.ps1" `
    -Authenticated
```

## Next

Part C will normalize results, capture artifacts, publish execution-result messages, and manage failed execution recovery.
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-Part-B-Live-Execution-Engine.md" $Guide

$ReleaseNotes = @'
# AI Office v1.1.3 Part B Release Notes

## Release

OpenClaw Live Execution Engine

## Added

- OpenClaw Gateway protocol v4 client
- WebSocket challenge and connect handling
- External token authentication
- Generic Gateway RPC calls
- Authenticated health checks
- Live agent execution
- Run waiting
- Message Bus consumption
- Execution-state persistence
- Failure propagation
- Validation suite

## Next

v1.1.3 Part C — Result and Artifact Processing
'@

Write-NewFile ".\docs\AI-Office-v1.1.3-Part-B-Release-Notes.md" $ReleaseNotes

$VersionPath = ".\config\identity\version.json"

if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw |
        ConvertFrom-Json

    $Version.version = "1.1.3"
    $Version.release_name = "OpenClaw Bridge"
    $Version.status = "part_b_installed"
    $Version.installed_at = (Get-Date).ToString("o")
    $Version.next_planned_milestone = "1.1.3 Part C Result Processing"

    $Version |
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $VersionPath -Encoding UTF8

    Write-Host "[UPDATED] Identity release metadata set to Part B" `
        -ForegroundColor Green
}

Write-Host ""
Write-Host "Validating Part B JSON files..." -ForegroundColor Cyan

@(
    ".\config\bridge\execution-policy.json",
    ".\config\bridge\execution-record-schema.json",
    ".\workspace\templates\openclaw-execution-record-template.json"
) | ForEach-Object {
    Get-Content -LiteralPath $_ -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] $_" -ForegroundColor Green
}

try {
    $Source = $MyInvocation.MyCommand.Path
    $Destination = Join-Path `
        $Repository `
        "Installers\AI-Office-v1.1.3-Part-B-Live-Execution-Engine-Install.ps1"

    if ($Source -and
        (Test-Path -LiteralPath $Source -PathType Leaf) -and
        [System.IO.Path]::GetFullPath($Source) -ne
        [System.IO.Path]::GetFullPath($Destination)) {
        Copy-Item `
            -LiteralPath $Source `
            -Destination $Destination `
            -Force

        Write-Host "[COPIED ] Installer saved to $Destination" `
            -ForegroundColor Green
    }
}
catch {
    Write-Host (
        "[WARNING] Installer copy was not completed: " +
        $_.Exception.Message
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "AI Office v1.1.3 Part B installation completed." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Run standard validation with:" -ForegroundColor Cyan
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\bridge\Test-AIOfficeLiveExecutionEngine.ps1"'
Write-Host ""
