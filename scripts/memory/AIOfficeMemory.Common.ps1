$script:AIOfficeMemoryRoot = $null

function Get-AIOfficeMemoryRoot {
    if ($script:AIOfficeMemoryRoot) {
        return $script:AIOfficeMemoryRoot
    }

    $script:AIOfficeMemoryRoot = (
        Resolve-Path (Join-Path $PSScriptRoot "..\..")
    ).Path

    return $script:AIOfficeMemoryRoot
}

function Read-AIOfficeMemoryJson {
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

function Write-AIOfficeMemoryJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $Parent = Split-Path -Parent $Path

    if ($Parent -and -not (Test-Path -LiteralPath $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 60 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeMemoryPolicy {
    $Root = Get-AIOfficeMemoryRoot

    return Read-AIOfficeMemoryJson `
        -Path (Join-Path $Root "config\memory\memory-policy.json")
}

function New-AIOfficeMemoryId {
    return (
        "MEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeMemoryScopePath {
    param(
        [Parameter(Mandatory=$true)][string]$Scope,
        [string]$Department = ""
    )

    $Root = Get-AIOfficeMemoryRoot

    switch ($Scope) {
        "global" {
            return Join-Path $Root "workspace\memory\global"
        }
        "chief-of-staff" {
            return Join-Path $Root "workspace\memory\chief-of-staff"
        }
        "personal" {
            return Join-Path $Root "workspace\memory\personal"
        }
        "business" {
            return Join-Path $Root "workspace\memory\business"
        }
        "shared" {
            return Join-Path $Root "workspace\memory\shared"
        }
        "department" {
            if ([string]::IsNullOrWhiteSpace($Department)) {
                throw "Department is required when Scope is department."
            }

            return Join-Path `
                $Root `
                ("workspace\memory\departments\" + $Department + "\records")
        }
        default {
            throw "Unsupported memory scope: $Scope"
        }
    }
}

function Test-AIOfficeMemoryScope {
    param(
        [Parameter(Mandatory=$true)][string]$Scope,
        [string]$Department = ""
    )

    $Policy = Get-AIOfficeMemoryPolicy

    if ($null -eq $Policy) {
        throw "Memory policy could not be loaded."
    }

    if (@($Policy.memory_scopes) -notcontains $Scope) {
        return $false
    }

    if ($Scope -eq "department" -and [string]::IsNullOrWhiteSpace($Department)) {
        return $false
    }

    return $true
}

function Test-AIOfficeMemoryType {
    param([Parameter(Mandatory=$true)][string]$MemoryType)

    $Policy = Get-AIOfficeMemoryPolicy

    if ($null -eq $Policy) {
        throw "Memory policy could not be loaded."
    }

    return @($Policy.memory_types) -contains $MemoryType
}
