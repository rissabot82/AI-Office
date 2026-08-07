param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

. "E:\AI\AI-Office\scripts\operations-integrations\AIOfficeOperations.Common.ps1"

$Root = "E:\AI\AI-Office\workspace\operations-integrations"

function Get-JsonRecords {
    param([string]$Directory,[string]$Filter="*.json")
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return @() }
    return @(
        Get-ChildItem -LiteralPath $Directory -Filter $Filter -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            try { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json } catch {}
        } |
        Where-Object { $null -ne $_ }
    )
}

$Intake = Get-JsonRecords "$Root\intake"
$Dispatch = Get-JsonRecords "$Root\dispatch"
$Integrations = Get-JsonRecords "$Root\integrations"
$Jobs = Get-JsonRecords "$Root\jobs"
$Runs = Get-JsonRecords "$Root\job-runs"
$Health = Get-JsonRecords "$Root\health"
$Discord = Get-JsonRecords "$Root\discord-intake"

$Healthy = @($Integrations | Where-Object { [string]$_.status -eq "connected" }).Count
$Degraded = @($Integrations | Where-Object { [string]$_.status -eq "degraded" }).Count
$Queued = @($Dispatch | Where-Object { [string]$_.status -eq "queued" -or [string]$_.status -eq "waiting" }).Count
$Failed = @($Dispatch | Where-Object { [string]$_.status -eq "failed" }).Count
$CompletedRuns = @($Runs | Where-Object { [string]$_.status -eq "completed" }).Count
$FailedRuns = @($Runs | Where-Object { [string]$_.status -eq "failed" }).Count

$RecentHealth = @(
    $Health |
    Sort-Object { try { [datetime]$_.checked_at } catch { [datetime]::MinValue } } -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        [ordered]@{
            integration_id = [string]$_.integration_id
            integration_name = [string]$_.integration_name
            status = [string]$_.status
            details = [string]$_.details
            checked_at = [string]$_.checked_at
        }
    }
)

$RecentDispatch = @(
    $Dispatch |
    Sort-Object { try { [datetime]$_.updated_at } catch { [datetime]::MinValue } } -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        [ordered]@{
            dispatch_id = [string]$_.dispatch_id
            title = [string]$_.intake_title
            destination = [string]$_.destination
            status = [string]$_.status
            attempts = [int]$_.attempts
            updated_at = [string]$_.updated_at
        }
    }
)

$RecentRuns = @(
    $Runs |
    Sort-Object { try { [datetime]$_.updated_at } catch { [datetime]::MinValue } } -Descending |
    Select-Object -First 10 |
    ForEach-Object {
        [ordered]@{
            job_run_id = [string]$_.job_run_id
            job_name = [string]$_.job_name
            status = [string]$_.status
            started_at = [string]$_.started_at
            completed_at = [string]$_.completed_at
        }
    }
)

$Snapshot = [ordered]@{
    schema_version = "1.0.0"
    version = "1.9.0"
    generated_at = (Get-Date).ToString("o")
    status = if ($Degraded -gt 0 -or $Failed -gt 0 -or $FailedRuns -gt 0) { "attention" } else { "operational" }
    metrics = [ordered]@{
        intake = $Intake.Count
        discord_intake = $Discord.Count
        dispatch_total = $Dispatch.Count
        dispatch_queued = $Queued
        dispatch_failed = $Failed
        integrations = $Integrations.Count
        integrations_healthy = $Healthy
        integrations_degraded = $Degraded
        jobs = $Jobs.Count
        job_runs = $Runs.Count
        job_runs_completed = $CompletedRuns
        job_runs_failed = $FailedRuns
    }
    integration_health = $RecentHealth
    recent_dispatch = $RecentDispatch
    recent_job_runs = $RecentRuns
}

$Destination = "E:\AI\AI-Office\dashboard\data\operations-integrations.json"
$Parent = Split-Path -Parent $Destination
New-Item -ItemType Directory -Path $Parent -Force | Out-Null
$Snapshot | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $Destination -Encoding UTF8

Write-Host "Operations and Integrations dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
