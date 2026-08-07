$script:AIOfficeFinancialRoot = "E:\AI\AI-Office"

function Read-AIOfficeFinancialJson {
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

function Write-AIOfficeFinancialJson {
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

function Get-AIOfficeFinancialPolicy {
    return Read-AIOfficeFinancialJson `
        -Path "E:\AI\AI-Office\config\financial-office\financial-policy.json"
}

function New-AIOfficeFinancialId {
    param([Parameter(Mandatory=$true)][string]$Prefix)

    return (
        $Prefix + "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeFinancialCollection {
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
            Read-AIOfficeFinancialJson -Path $_.FullName
        } |
        Where-Object { $null -ne $_ }
    )
}
