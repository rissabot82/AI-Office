$script:AIOfficeCollaborationRoot = "E:\AI\AI-Office"

function Read-AIOfficeCollaborationJson {
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

function Write-AIOfficeCollaborationJson {
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

function Get-AIOfficeCollaborationPolicy {
    return Read-AIOfficeCollaborationJson `
        -Path "E:\AI\AI-Office\config\multi-agent\collaboration-policy.json"
}

function New-AIOfficeHandoffId {
    return "HOF-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$(([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpperInvariant())"
}

function New-AIOfficeAgentReviewId {
    return "REVAGT-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$(([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpperInvariant())"
}

function New-AIOfficeConsensusId {
    return "CNS-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$(([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpperInvariant())"
}

function New-AIOfficeConflictId {
    return "CNF-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$(([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpperInvariant())"
}
