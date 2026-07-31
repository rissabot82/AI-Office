$script:AIOfficeMessagingRoot = $null

function Get-AIOfficeMessagingRoot {
    if ($script:AIOfficeMessagingRoot) {
        return $script:AIOfficeMessagingRoot
    }

    $script:AIOfficeMessagingRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeMessagingRoot
}

function Read-AIOfficeMessagingJson {
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

function Write-AIOfficeMessagingJson {
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

function ConvertTo-AIOfficeMessageArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function New-AIOfficeMessageId {
    $Stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $Suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return "MSG-$Stamp-$Suffix"
}

function New-AIOfficeCorrelationId {
    return "COR-" + (
        [guid]::NewGuid().ToString("N").Substring(0,12)
    ).ToUpperInvariant()
}

function New-AIOfficeConversationId {
    param([string]$Topic = "GENERAL")

    $SafeTopic = ($Topic.ToUpperInvariant() -replace "[^A-Z0-9-]", "-")
    $Stamp = (Get-Date).ToString("yyyyMMdd")
    $Suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()

    return "CONV-$SafeTopic-$Stamp-$Suffix"
}

function Get-AIOfficeMessagingPolicy {
    $Root = Get-AIOfficeMessagingRoot

    return Read-AIOfficeMessagingJson `
        -Path (Join-Path $Root "config\messaging\messaging-policy.json")
}

function Get-AIOfficeMessagingIdentity {
    $Root = Get-AIOfficeMessagingRoot
    $Path = Join-Path $Root "config\identity\office.json"

    $Identity = Read-AIOfficeMessagingJson -Path $Path

    if ($null -eq $Identity) {
        throw "AI Office identity is required. Install v1.1.1 first."
    }

    return $Identity
}

function Get-AIOfficeMessageQueuePath {
    param([Parameter(Mandatory=$true)][string]$Queue)

    $Allowed = @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )

    if ($Allowed -notcontains $Queue) {
        throw "Unsupported message queue: $Queue"
    }

    $Root = Get-AIOfficeMessagingRoot
    return Join-Path $Root ("workspace\messages\" + $Queue)
}

function Test-AIOfficeMessageShape {
    param([Parameter(Mandatory=$true)]$Message)

    $Required = @(
        "message_id",
        "correlation_id",
        "conversation_id",
        "office_id",
        "office_version",
        "from",
        "to",
        "message_type",
        "priority",
        "status",
        "created_at",
        "delivery_attempts",
        "payload",
        "history"
    )

    foreach ($Name in $Required) {
        if ($null -eq $Message.PSObject.Properties[$Name]) {
            return $false
        }
    }

    return $true
}
