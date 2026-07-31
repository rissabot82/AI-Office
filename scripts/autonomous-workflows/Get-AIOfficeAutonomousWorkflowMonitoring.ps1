param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Policy = Get-AIOfficeAutonomousWorkerPolicy
$Now = Get-Date
$Runs = New-Object System.Collections.Generic.List[object]
$Warnings = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\runs" `
        -Filter "RUN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $Run = Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName

    if ($null -eq $Run) {
        continue
    }

    $Runs.Add($Run)

    $UpdatedAt = [datetime]$Run.updated_at
    $AgeHours = ($Now - $UpdatedAt).TotalHours

    if (
        @("queued","running","waiting") -contains [string]$Run.status -and
        $AgeHours -ge [double]$Policy.monitoring.warning_run_after_hours
    ) {
        $Warnings.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            warning_type = if (
                $AgeHours -ge [double]$Policy.monitoring.stale_run_after_hours
            ) {
                "stale_run"
            }
            else {
                "long_running"
            }
            age_hours = [math]::Round($AgeHours, 2)
            status = [string]$Run.status
        })
    }

    if ([string]$Run.status -eq "waiting_approval") {
        $Warnings.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            warning_type = "waiting_approval"
            age_hours = [math]::Round($AgeHours, 2)
            status = [string]$Run.status
        })
    }

    if ([string]$Run.status -eq "failed") {
        $Warnings.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            warning_type = "failed_run"
            age_hours = [math]::Round($AgeHours, 2)
            status = [string]$Run.status
        })
    }
}

$MonitoringId = New-AIOfficeAutonomousMonitoringId
$Status = if ($Warnings.Count -gt 0) {
    "attention_required"
}
else {
    "healthy"
}

$Report = [ordered]@{
    monitoring_id = $MonitoringId
    generated_at = (Get-Date).ToString("o")
    status = $Status
    active_run_count = @(
        $Runs |
            Where-Object {
                @("queued","running","waiting") -contains [string]$_.status
            }
    ).Count
    waiting_approval_count = @(
        $Runs | Where-Object { [string]$_.status -eq "waiting_approval" }
    ).Count
    failed_run_count = @(
        $Runs | Where-Object { [string]$_.status -eq "failed" }
    ).Count
    completed_run_count = @(
        $Runs | Where-Object { [string]$_.status -eq "completed" }
    ).Count
    warning_count = $Warnings.Count
    warnings = @($Warnings | ForEach-Object { $_ })
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Report `
    -Path (
        ".\workspace\autonomous-workflows\monitoring\" +
        $MonitoringId +
        ".json"
    )

Write-Host (
    "Autonomous workflow monitoring report created: " +
    $MonitoringId
) -ForegroundColor Green

return [pscustomobject]$Report
