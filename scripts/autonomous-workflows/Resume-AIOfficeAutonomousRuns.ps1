param(
    [string]$RunId = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Policy = Get-AIOfficeAutonomousExecutionPolicy
$Runs = New-Object System.Collections.Generic.List[object]

if ($RunId) {
    $Runs.Add((Get-AIOfficeAutonomousRun -RunId $RunId))
}
else {
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath ".\workspace\autonomous-workflows\runs" `
            -Filter "RUN-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Run = Read-AIOfficeAutonomousWorkflowJson -Path $File.FullName

        if (
            $null -ne $Run -and
            @($Policy.recovery.resume_statuses) -contains [string]$Run.status
        ) {
            $Runs.Add($Run)
        }
    }
}

$Recovered = New-Object System.Collections.Generic.List[object]

foreach ($Run in $Runs) {
    $PreviousStatus = [string]$Run.status
    $RecoveredStatus = $PreviousStatus

    if ($PreviousStatus -in @("queued","running","waiting")) {
        $RecoveredStatus = "running"
    }

    if ($PreviousStatus -eq "waiting_approval") {
        $RecoveredStatus = "waiting_approval"
    }

    $Run.status = $RecoveredStatus
    $Run.updated_at = (Get-Date).ToString("o")
    Save-AIOfficeAutonomousRun -Run $Run

    $RecoveryId = New-AIOfficeAutonomousRecoveryId
    $Record = [ordered]@{
        recovery_id = $RecoveryId
        run_id = [string]$Run.run_id
        previous_status = $PreviousStatus
        recovered_status = $RecoveredStatus
        checkpoint_id = [string]$Run.last_checkpoint_id
        created_at = (Get-Date).ToString("o")
    }

    Write-AIOfficeAutonomousWorkflowJson `
        -Value $Record `
        -Path ".\workspace\autonomous-workflows\recovery\$RecoveryId.json"

    $Recovered.Add([pscustomobject]$Record)
}

& ".\scripts\autonomous-workflows\Update-AIOfficeAutonomousWorkflowIndex.ps1" |
    Out-Null

Write-Host (
    "Autonomous workflow recovery completed: " +
    $Recovered.Count.ToString() +
    " run(s)"
) -ForegroundColor Green

return @($Recovered | ForEach-Object { $_ })
