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
