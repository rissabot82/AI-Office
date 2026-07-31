function Get-AIOfficeCalendarRoot {
    $repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    return $repositoryRoot.Path
}

function ConvertTo-AIOfficeDateTime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $parsed = [datetime]::MinValue

    if (-not [datetime]::TryParse($Value, [ref]$parsed)) {
        throw "Invalid date or date-time value: $Value"
    }

    return $parsed
}

function Get-AIOfficeUrgencyScore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Priority,

        [Parameter(Mandatory = $true)]
        [datetime]$StartAt,

        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    if ($Status -in @("completed", "cancelled", "archived")) {
        return 0
    }

    $priorityScores = @{
        critical = 100
        high = 70
        normal = 40
        low = 10
    }

    $score = [int]$priorityScores[$Priority]
    $now = Get-Date
    $today = $now.Date
    $daysUntil = [math]::Floor(($StartAt.Date - $today).TotalDays)

    if ($StartAt -lt $now) {
        $score += 100
    }
    elseif ($StartAt.Date -eq $today) {
        $score += 60
    }
    elseif ($daysUntil -le 7) {
        $score += 30
    }
    elseif ($daysUntil -le 30) {
        $score += 10
    }

    return $score
}

function Get-AIOfficeEventFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EventId
    )

    $root = Get-AIOfficeCalendarRoot
    return Join-Path $root "workspace\calendar\events\$EventId\event.json"
}

function Save-AIOfficeEvent {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Event,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Event |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AIOfficeEvent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EventId
    )

    $path = Get-AIOfficeEventFile -EventId $EventId

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Calendar event not found: $EventId"
    }

    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}
