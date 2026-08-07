$script:AIOfficeEnterpriseRoot = "E:\AI\AI-Office"

function Read-AIOfficeEnterpriseJson {
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

function Write-AIOfficeEnterpriseJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 100 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeEnterprisePolicy {
    return Read-AIOfficeEnterpriseJson `
        -Path "E:\AI\AI-Office\config\autonomous-enterprise\enterprise-policy.json"
}

function New-AIOfficeEnterpriseId {
    param([Parameter(Mandatory=$true)][string]$Prefix)

    return (
        $Prefix + "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeEnterpriseCollection {
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [Parameter(Mandatory=$true)][string]$Filter
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Directory `
            -Filter $Filter `
            -File `
            -ErrorAction SilentlyContinue |
        ForEach-Object {
            Read-AIOfficeEnterpriseJson -Path $_.FullName
        } |
        Where-Object { $null -ne $_ }
    )
}

function Get-AIOfficeEnterpriseWorkById {
    param([Parameter(Mandatory=$true)][string]$EnterpriseWorkId)

    $Path = "E:\AI\AI-Office\workspace\autonomous-enterprise\work-items\$EnterpriseWorkId.json"
    $Work = Read-AIOfficeEnterpriseJson -Path $Path

    if ($null -eq $Work) {
        throw "Enterprise work item not found: $EnterpriseWorkId"
    }

    return $Work
}
