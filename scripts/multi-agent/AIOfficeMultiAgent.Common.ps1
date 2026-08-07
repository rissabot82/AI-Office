$script:AIOfficeMultiAgentRoot = "E:\AI\AI-Office"

function Get-AIOfficeMultiAgentRoot {
    return $script:AIOfficeMultiAgentRoot
}

function Read-AIOfficeMultiAgentJson {
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

function Write-AIOfficeMultiAgentJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 80 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeMultiAgentPolicy {
    return Read-AIOfficeMultiAgentJson `
        -Path "E:\AI\AI-Office\config\multi-agent\agent-policy.json"
}

function New-AIOfficeAgentId {
    return (
        "AGT-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeAssignmentId {
    return (
        "ASN-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeCollaborationId {
    return (
        "COL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeAgent {
    param([Parameter(Mandatory=$true)][string]$AgentId)

    $Path = "E:\AI\AI-Office\workspace\multi-agent\agents\$AgentId.json"
    $Agent = Read-AIOfficeMultiAgentJson -Path $Path

    if ($null -eq $Agent) {
        throw "Agent not found: $AgentId"
    }

    return $Agent
}
