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
