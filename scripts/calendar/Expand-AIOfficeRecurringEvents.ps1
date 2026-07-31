param(
    [int]$DaysAhead = 90,
    [string]$CreatedBy = "calendar-engine"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeCalendar.Common.ps1")

$repositoryRoot = Get-AIOfficeCalendarRoot
Set-Location $repositoryRoot

$eventFiles = Get-ChildItem `
    -Path ".\workspace\calendar\events" `
    -Filter "event.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue

$windowEnd = (Get-Date).Date.AddDays($DaysAhead)
$createdCount = 0

foreach ($eventFile in $eventFiles) {
    $event = Get-Content -LiteralPath $eventFile.FullName -Raw | ConvertFrom-Json

    if ($event.recurrence.frequency -eq "none") {
        continue
    }

    if ($event.tags -contains "recurrence-instance") {
        continue
    }

    $originalStart = ConvertTo-AIOfficeDateTime -Value ([string]$event.start_at)
    $originalEnd = ConvertTo-AIOfficeDateTime -Value ([string]$event.end_at)
    $duration = $originalEnd - $originalStart
    $nextStart = $originalStart
    $generated = 0
    $maximumCount = $event.recurrence.count
    $until = $null

    if (-not [string]::IsNullOrWhiteSpace([string]$event.recurrence.until)) {
        $until = ConvertTo-AIOfficeDateTime -Value ([string]$event.recurrence.until)
    }

    while ($true) {
        switch ([string]$event.recurrence.frequency) {
            "daily" {
                $nextStart = $nextStart.AddDays([int]$event.recurrence.interval)
            }
            "weekly" {
                $nextStart = $nextStart.AddDays(7 * [int]$event.recurrence.interval)
            }
            "monthly" {
                $nextStart = $nextStart.AddMonths([int]$event.recurrence.interval)
            }
            "yearly" {
                $nextStart = $nextStart.AddYears([int]$event.recurrence.interval)
            }
        }

        $generated++

        if ($nextStart -gt $windowEnd) {
            break
        }

        if ($null -ne $until -and $nextStart -gt $until) {
            break
        }

        if ($null -ne $maximumCount -and $generated -ge [int]$maximumCount) {
            break
        }

        $instanceKey = "recurrence:{0}:{1}" -f $event.event_id, $nextStart.ToString("yyyyMMddHHmm")
        $existing = Get-ChildItem `
            -Path ".\workspace\calendar\events" `
            -Filter "event.json" `
            -File `
            -Recurse |
            ForEach-Object {
                try {
                    Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
                }
                catch {
                    $null
                }
            } |
            Where-Object {
                $null -ne $_ -and @($_.tags) -contains $instanceKey
            }

        if ($existing) {
            continue
        }

        $newTags = @($event.tags) + @(
            "recurrence-instance",
            $instanceKey,
            ("parent:{0}" -f $event.event_id)
        )

        $parameters = @{
            Title = [string]$event.title
            Description = [string]$event.description
            EventType = [string]$event.event_type
            Priority = [string]$event.priority
            StartAt = $nextStart.ToString("yyyy-MM-ddTHH:mm:ss")
            EndAt = $nextStart.Add($duration).ToString("yyyy-MM-ddTHH:mm:ss")
            EstimatedMinutes = [int]$event.estimated_minutes
            Timezone = [string]$event.timezone
            OwnerAgent = [string]$event.owner_agent
            CreatedBy = $CreatedBy
            Location = [string]$event.location
            Recurrence = "none"
            ProjectId = [string]$event.links.project_id
            WorkflowId = [string]$event.links.workflow_id
            TaskId = [string]$event.links.task_id
            KnowledgeIds = @($event.links.knowledge_ids)
            Tags = $newTags
        }

        if ($event.all_day) {
            $parameters.AllDay = $true
        }

        & ".\scripts\calendar\New-AIOfficeEvent.ps1" @parameters | Out-Null
        $createdCount++
    }
}

Write-Host "Recurring event expansion complete: $createdCount event(s) created." -ForegroundColor Green
