$script:AIOfficeBridgeRoot = $null

function Get-AIOfficeBridgeRoot {
    if ($script:AIOfficeBridgeRoot) {
        return $script:AIOfficeBridgeRoot
    }

    $script:AIOfficeBridgeRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeBridgeRoot
}

function Read-AIOfficeBridgeJson {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Write-AIOfficeBridgeJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 50 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function New-AIOfficeBridgeRequestId {
    return (
        "BRQ-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeBridgeResultId {
    return (
        "BRR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeBridgePolicy {
    $Root = Get-AIOfficeBridgeRoot

    return Read-AIOfficeBridgeJson `
        -Path (Join-Path $Root "config\bridge\bridge-policy.json")
}

function Get-AIOfficeBridgeApprovalPolicy {
    $Root = Get-AIOfficeBridgeRoot

    return Read-AIOfficeBridgeJson `
        -Path (Join-Path $Root "config\bridge\approval-policy.json")
}

function Test-AIOfficeBridgeApproval {
    param(
        [Parameter(Mandatory=$true)][string]$RiskLevel,
        [Parameter(Mandatory=$true)][string]$ApprovalStatus
    )

    $ApprovalPolicy = Get-AIOfficeBridgeApprovalPolicy

    if ($null -eq $ApprovalPolicy) {
        throw "Bridge approval policy could not be loaded."
    }

    $Rule = @(
        $ApprovalPolicy.approval_rules |
            Where-Object { [string]$_.risk_level -eq $RiskLevel }
    ) | Select-Object -First 1

    if ($null -eq $Rule) {
        return $false
    }

    if (-not [bool]$Rule.approval_required) {
        return $true
    }

    return [string]$ApprovalStatus -eq "approved"
}

function Test-AIOfficeOpenClawGatewayPort {
    param(
        [string]$HostName = "localhost",
        [int]$Port = 18789,
        [int]$TimeoutMilliseconds = 1500
    )

    $Client = New-Object System.Net.Sockets.TcpClient

    try {
        $Async = $Client.BeginConnect($HostName, $Port, $null, $null)
        $Connected = $Async.AsyncWaitHandle.WaitOne(
            $TimeoutMilliseconds,
            $false
        )

        if (-not $Connected) {
            return $false
        }

        $Client.EndConnect($Async)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $Client.Close()
    }
}
