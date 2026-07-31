$script:AIOfficeDepartmentRoot = $null

function Get-AIOfficeDepartmentRoot {
    if ($script:AIOfficeDepartmentRoot) {
        return $script:AIOfficeDepartmentRoot
    }

    $script:AIOfficeDepartmentRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeDepartmentRoot
}

function Read-AIOfficeDepartmentJson {
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

function Write-AIOfficeDepartmentJson {
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

function Get-AIOfficeDepartmentPolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-intelligence-policy.json")
}

function Get-AIOfficeDepartmentProfile {
    param([Parameter(Mandatory=$true)][string]$Department)

    $Root = Get-AIOfficeDepartmentRoot
    $Path = Join-Path `
        $Root `
        ("config\departments\" + $Department + "\department-profile.json")

    $Profile = Read-AIOfficeDepartmentJson -Path $Path

    if ($null -eq $Profile) {
        throw "Department profile not found: $Department"
    }

    return $Profile
}

function Test-AIOfficeDepartmentCapability {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$Capability
    )

    $Profile = Get-AIOfficeDepartmentProfile -Department $Department

    return @($Profile.capabilities) -contains $Capability
}
