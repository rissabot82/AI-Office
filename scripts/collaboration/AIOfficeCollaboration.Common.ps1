$script:AIOfficeCollaborationRoot = $null

function Get-AIOfficeCollaborationRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeCollaborationRoot)) {
        return $script:AIOfficeCollaborationRoot
    }

    $resolved = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $script:AIOfficeCollaborationRoot = $resolved.Path
    return $script:AIOfficeCollaborationRoot
}

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

    $parent = Split-Path -Parent $Path

    if (-not [string]::IsNullOrWhiteSpace($parent) -and
        -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function ConvertTo-AIOfficeCollaborationArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function New-AIOfficeCollaborationId {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("MSG","DEL","CNF","CTX")]
        [string]$Prefix
    )

    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return $Prefix + "-" + $stamp + "-" + $suffix
}

function Get-AIOfficeAgentPath {
    param([Parameter(Mandatory=$true)][string]$AgentId)

    $root = Get-AIOfficeCollaborationRoot
    return Join-Path $root ("workspace\collaboration\agents\" + $AgentId + ".json")
}

function Get-AIOfficeAgent {
    param([Parameter(Mandatory=$true)][string]$AgentId)

    $path = Get-AIOfficeAgentPath -AgentId $AgentId
    return Read-AIOfficeCollaborationJson -Path $path
}
