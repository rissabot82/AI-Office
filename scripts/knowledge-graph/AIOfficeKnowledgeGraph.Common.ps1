$script:AIOfficeKnowledgeGraphRoot = "E:\AI\AI-Office"

function Get-AIOfficeKnowledgeGraphRoot {
    return $script:AIOfficeKnowledgeGraphRoot
}

function Read-AIOfficeKnowledgeGraphJson {
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

function Write-AIOfficeKnowledgeGraphJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeKnowledgeGraphPolicy {
    return Read-AIOfficeKnowledgeGraphJson -Path "E:\AI\AI-Office\config\knowledge-graph\graph-policy.json"
}

function New-AIOfficeKnowledgeGraphEntityId {
    return "KGE-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$(([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpperInvariant())"
}

function New-AIOfficeKnowledgeGraphRelationshipId {
    return "KGR-$((Get-Date).ToString('yyyyMMdd-HHmmss'))-$(([guid]::NewGuid().ToString('N').Substring(0,6)).ToUpperInvariant())"
}

function Get-AIOfficeKnowledgeGraphEntity {
    param([Parameter(Mandatory=$true)][string]$EntityId)

    $Path = "E:\AI\AI-Office\workspace\knowledge-graph\entities\$EntityId.json"
    $Entity = Read-AIOfficeKnowledgeGraphJson -Path $Path

    if ($null -eq $Entity) {
        throw "Knowledge Graph entity not found: $EntityId"
    }

    return $Entity
}
