param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$true)][string]$StepId,
    [ValidateSet("before","after","recovery","failure")]
    [string]$Stage,
    [Parameter(Mandatory=$true)][string]$StateJson
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutonomousWorkflows.Common.ps1")

$Root = Get-AIOfficeAutonomousWorkflowRoot
Set-Location $Root

try {
    $State = $StateJson | ConvertFrom-Json
}
catch {
    throw "StateJson is invalid: $($_.Exception.Message)"
}

$RunPath = ".\workspace\autonomous-workflows\runs\$RunId.json"
$Run = Read-AIOfficeAutonomousWorkflowJson -Path $RunPath

if ($null -eq $Run) {
    throw "Autonomous workflow run not found: $RunId"
}

$CheckpointId = New-AIOfficeAutonomousCheckpointId

$Checkpoint = [ordered]@{
    checkpoint_id = $CheckpointId
    run_id = $RunId
    step_id = $StepId
    stage = $Stage
    state = $State
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Checkpoint `
    -Path ".\workspace\autonomous-workflows\checkpoints\$CheckpointId.json"

$Run.last_checkpoint_id = $CheckpointId
$Run.updated_at = (Get-Date).ToString("o")

Write-AIOfficeAutonomousWorkflowJson `
    -Value $Run `
    -Path $RunPath

Write-Host "Workflow checkpoint created: $CheckpointId" -ForegroundColor Green
return [pscustomobject]$Checkpoint
