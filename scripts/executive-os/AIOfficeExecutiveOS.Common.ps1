$script:AIOfficeExecutiveOSRoot = $null

function Get-AIOfficeExecutiveOSRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeExecutiveOSRoot)) {
        return $script:AIOfficeExecutiveOSRoot
    }

    $resolved = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $script:AIOfficeExecutiveOSRoot = $resolved.Path
    return $script:AIOfficeExecutiveOSRoot
}

function Read-AIOfficeExecutiveOSJson {
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

function Write-AIOfficeExecutiveOSJson {
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
        ConvertTo-Json -Depth 40 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function ConvertTo-AIOfficeExecutiveOSArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function Get-AIOfficeFileCount {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Filter = "*.json"
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return 0
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Path `
            -Filter $Filter `
            -File `
            -ErrorAction SilentlyContinue
    ).Count
}

function Get-AIOfficeLatestFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Filter = "*"
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $null
    }

    return Get-ChildItem `
        -LiteralPath $Path `
        -Filter $Filter `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Update-AIOfficeExecutiveOSIndexField {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [AllowNull()]$Value
    )

    $root = Get-AIOfficeExecutiveOSRoot
    $path = Join-Path $root "workspace\executive-os\executive-os-index.json"
    $index = Read-AIOfficeExecutiveOSJson -Path $path

    if ($null -eq $index) {
        $index = [pscustomobject]@{
            version = "1.0.0"
            updated_at = ""
            last_startup_at = ""
            last_daily_briefing_at = ""
            last_end_of_day_report_at = ""
            last_weekly_report_at = ""
            last_monthly_report_at = ""
            office_health_score = 0
            office_health_status = "unknown"
            latest_briefing = ""
            latest_report = ""
        }
    }

    if ($null -ne $index.PSObject.Properties[$Name]) {
        $index.$Name = $Value
    }
    else {
        $index | Add-Member `
            -MemberType NoteProperty `
            -Name $Name `
            -Value $Value
    }

    $index.updated_at = (Get-Date).ToString("o")
    Write-AIOfficeExecutiveOSJson -Value $index -Path $path
}
