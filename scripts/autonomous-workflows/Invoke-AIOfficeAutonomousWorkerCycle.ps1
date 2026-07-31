param(
    [int]$MaximumRuns = 10,
    [int]$MaximumStepsPerRun = 25,
    [switch]$SkipRecovery
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorker.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Policy = Get-AIOfficeAutonomousWorkerPolicy
$CycleId = New-AIOfficeAutonomousWorkerCycleId
$StartedAt = (Get-Date).ToString("o")

$Recovered = @()

if (-not $SkipRecovery -and [bool]$Policy.worker.recover_before_processing) {
    $Recovered = @(
        & ".\scripts\autonomous-workflows\Resume-AIOfficeAutonomousRuns.ps1"
    )
}

$RunFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\autonomous-workflows\runs" `
        -Filter "RUN-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$Candidates = New-Object System.Collections.Generic.List[object]

foreach ($File in $RunFiles) {
    $Run = Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName

    if ($null -eq $Run) {
        continue
    }

    if (@("queued","running","waiting") -contains [string]$Run.status) {
        $Candidates.Add($Run)
    }
}

$Candidates = @(
    $Candidates |
        Sort-Object created_at |
        Select-Object -First $MaximumRuns
)

$Results = New-Object System.Collections.Generic.List[object]

foreach ($Run in $Candidates) {
    $BeforeStatus = [string]$Run.status

    try {
        $Updated = & ".\scripts\autonomous-workflows\Invoke-AIOfficeAutonomousRun.ps1" `
            -RunId ([string]$Run.run_id) `
            -MaximumSteps $MaximumStepsPerRun

        $Results.Add([pscustomobject]@{
            run_id = [string]$Updated.run_id
            before_status = $BeforeStatus
            after_status = [string]$Updated.status
            error = ""
        })
    }
    catch {
        $Results.Add([pscustomobject]@{
            run_id = [string]$Run.run_id
            before_status = $BeforeStatus
            after_status = "failed"
            error = $_.Exception.Message
        })
    }
}

$CompletedAt = (Get-Date).ToString("o")
$FailedCount = @(
    $Results | Where-Object { [string]$_.after_status -eq "failed" }
).Count

$Cycle = [ordered]@{
    worker_cycle_id = $CycleId
    started_at = $StartedAt
    completed_at = $CompletedAt
    status = if ($FailedCount -gt 0) { "completed_with_errors" } else { "completed" }
    recovered_run_count = $Recovered.Count
    processed_run_count = $Results.Count
    completed_run_count = @(
        $Results | Where-Object { [string]$_.after_status -eq "completed" }
    ).Count
    failed_run_count = $FailedCount
    waiting_approval_count = @(
        $Results | Where-Object { [string]$_.after_status -eq "waiting_approval" }
    ).Count
    runs = @($Results | ForEach-Object { $_ })
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Cycle `
    -Path (
        ".\workspace\autonomous-workflows\workers\history\" +
        $CycleId +
        ".json"
    )

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host (
    "Autonomous worker cycle completed: " +
    $CycleId +
    " | " +
    $Results.Count.ToString() +
    " run(s)"
) -ForegroundColor Green

return [pscustomobject]$Cycle
