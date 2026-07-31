$script:AIOfficeChiefOfStaffRoot = $null

function Get-AIOfficeChiefOfStaffRoot {
    if ($script:AIOfficeChiefOfStaffRoot) {
        return $script:AIOfficeChiefOfStaffRoot
    }

    $script:AIOfficeChiefOfStaffRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeChiefOfStaffRoot
}

function Read-AIOfficeChiefOfStaffJson {
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

function Write-AIOfficeChiefOfStaffJson {
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

function New-AIOfficeChiefOfStaffPlanId {
    return (
        "PLAN-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeChiefOfStaffDecisionId {
    return (
        "DEC-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\chief-of-staff-policy.json")
}

function Test-AIOfficeChiefOfStaffApprovalRequired {
    param([Parameter(Mandatory=$true)][string]$RiskLevel)

    $Policy = Get-AIOfficeChiefOfStaffPolicy

    if ($null -eq $Policy) {
        throw "Chief of Staff policy could not be loaded."
    }

    return @($Policy.risk.approval_required) -contains $RiskLevel
}
