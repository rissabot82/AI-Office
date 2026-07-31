param(
    [string]$Query = "",
    [string]$EventType = "",
    [string]$Status = "",
    [string]$Priority = "",
    [string]$OwnerAgent = "",
    [string]$Tag = "",
    [string]$From = "",
    [string]$To = "",
    [int]$Limit = 50,
    [switch]$IncludeCompleted,
    [switch]$IncludeCancelled
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

$index = Get-Content `
    -LiteralPath ".\workspace\calendar\calendar-index.json" `
    -Raw |
    ConvertFrom-Json

$results = @($index.events)

if (-not $IncludeCompleted) {
    $results = @($results | Where-Object { $_.status -ne "completed" })
}

if (-not $IncludeCancelled) {
    $results = @($results | Where-Object { $_.status -ne "cancelled" })
}

if (-not [string]::IsNullOrWhiteSpace($Query)) {
    $queryText = $Query.ToLowerInvariant()
    $results = @(
        $results | Where-Object {
            ([string]$_.search_text).Contains($queryText)
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($EventType)) {
    $results = @($results | Where-Object { $_.event_type -eq $EventType })
}

if (-not [string]::IsNullOrWhiteSpace($Status)) {
    $results = @($results | Where-Object { $_.status -eq $Status })
}

if (-not [string]::IsNullOrWhiteSpace($Priority)) {
    $results = @($results | Where-Object { $_.priority -eq $Priority })
}

if (-not [string]::IsNullOrWhiteSpace($OwnerAgent)) {
    $results = @($results | Where-Object { $_.owner_agent -eq $OwnerAgent })
}

if (-not [string]::IsNullOrWhiteSpace($Tag)) {
    $tagText = $Tag.Trim().ToLowerInvariant()
    $results = @($results | Where-Object { @($_.tags) -contains $tagText })
}

if (-not [string]::IsNullOrWhiteSpace($From)) {
    $fromDate = ConvertTo-AIOfficeDateTime -Value $From
    $results = @(
        $results | Where-Object {
            (ConvertTo-AIOfficeDateTime -Value ([string]$_.start_at)) -ge $fromDate
        }
    )
}

if (-not [string]::IsNullOrWhiteSpace($To)) {
    $toDate = ConvertTo-AIOfficeDateTime -Value $To
    $results = @(
        $results | Where-Object {
            (ConvertTo-AIOfficeDateTime -Value ([string]$_.start_at)) -le $toDate
        }
    )
}

$results = @(
    $results |
    Sort-Object `
        @{ Expression = { $_.urgency_score }; Descending = $true },
        @{ Expression = { $_.start_at }; Descending = $false } |
    Select-Object -First $Limit
)

Write-Host ""
Write-Host "Calendar search results: $($results.Count)" -ForegroundColor Cyan
Write-Host ""

if ($results.Count -eq 0) {
    Write-Host "No matching calendar events were found." -ForegroundColor Yellow
    exit 0
}

$rows = foreach ($event in $results) {
    [PSCustomObject]@{
        EventId = $event.event_id
        Start = $event.start_at
        Type = $event.event_type
        Priority = $event.priority
        Status = $event.status
        Urgency = $event.urgency_score
        Title = $event.title
    }
}

$rows | Format-Table -AutoSize
