param(
    [Parameter(Mandatory = $true)]
    [string]$EventId,

    [string]$ArchivedBy = "Clarissa",
    [string]$Reason = "Calendar event archived."
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$eventFolder = Join-Path ".\workspace\calendar\events" $EventId
$eventPath = Join-Path $eventFolder "event.json"

if (-not (Test-Path -LiteralPath $eventPath -PathType Leaf)) {
    throw "Calendar event not found: $EventId"
}

$event = Get-Content -LiteralPath $eventPath -Raw | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$event.status = "archived"
$event.updated_at = $timestamp
$event.urgency_score = 0
$event.history = @($event.history) + [PSCustomObject]@{
    timestamp = $timestamp
    action = "event-archived"
    actor = $ArchivedBy
    details = $Reason
}

Save-AIOfficeEvent -Event $event -Path $eventPath

$archiveFolder = Join-Path ".\workspace\calendar\archive" $EventId

if (-not (Test-Path -LiteralPath $archiveFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
}

Copy-Item -Path (Join-Path $eventFolder "*") -Destination $archiveFolder -Recurse -Force

& ".\scripts\calendar\Update-AIOfficeCalendarIndex.ps1" | Out-Null

Write-Host ""
Write-Host "Calendar event archived successfully." -ForegroundColor Green
Write-Host "Event ID:     $EventId"
Write-Host "Archive copy: $archiveFolder"
