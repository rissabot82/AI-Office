param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$StepId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousExecution.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

$Run = Get-AIOfficeAutonomousRun -RunId $RunId
$Plan = Get-AIOfficeAutonomousPlan `
    -AutonomousPlanId ([string]$Run.autonomous_plan_id)

$Step = @(
    $Plan.steps |
        Where-Object { [string]$_.step_id -eq $StepId }
) | Select-Object -First 1

if ($null -eq $Step) {
    throw "Workflow step not found: $StepId"
}

if ([int]$Step.attempt_count -ge [int]$Step.max_attempts) {
    throw "Maximum retry attempts reached for step $StepId."
}

$RetryId = (
    "RTY-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss") +
    "-" +
    ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
)

$Retry = [ordered]@{
    retry_id = $RetryId
    run_id = $RunId
    step_id = $StepId
    attempt_number = ([int]$Step.attempt_count + 1)
    created_at = (Get-Date).ToString("o")
    status = "queued"
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Retry `
    -Path ".\workspace\autonomous-workflows\retries\$RetryId.json"

$Step.status = "pending"
$Plan.status = "running"
$Plan.updated_at = (Get-Date).ToString("o")
Save-AIOfficeAutonomousPlan -Plan $Plan

$Run.status = "running"
$Run.updated_at = (Get-Date).ToString("o")
Save-AIOfficeAutonomousRun -Run $Run

Write-Host "Autonomous workflow retry queued: $RetryId" `
    -ForegroundColor Green

return [pscustomobject]$Retry
